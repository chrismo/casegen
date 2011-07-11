require 'singleton'

class Fixnum
  def even?
    self.divmod(2)[1] == 0
  end
end

class String
  def outdent
    a = $1 if match(/\A(\s*)(.*\n)(?:\1.*\n|\n)*\z/)
    gsub(/^#{a}/, '')
  end
end

module CLabs
  module CaseGen
    class AgentException < Exception
    end
  
    class Agent # base class
      attr_reader :data, :reference_agents
    
      def initialize(data, agents)
        @data = data
        @reference_agents = agents
      end
    end

    class Agents
      include Singleton
      
      def initialize
        clear
      end
      
      def register(agent)
        if agent.class == Class && agent.ancestors.include?(Agent)
          @agents << agent
        else
          raise AgentException.new("To register an agent, you must pass in a Class instance that's a subclass of Agent")
        end
      end
      
      def method_missing(methid, *args, &block)
        @agents.send(methid, *args, &block)
      end
      
      def get_agent_by_id(id)
        @agents.each do |agent| return agent if agent.agent_id =~ /#{id}/i end
        # rather than return nil and allow the client to get bumfuzzled if 
        # they forget to check for nil, let's blow up and tell them how to
        # not let it happen again
        raise AgentException.new("Requested an agent that does not exist. You can query for existance with .id_registered?")
      end
      
      def id_registered?(id)
        begin
          get_agent_by_id(id)
          return true
        rescue AgentException
          return false
        end
      end
      
      # removes all registered agents
      def clear
        @agents = []
      end
    end
    
    class ParserException < Exception
    end
    
    class Parser
      attr_reader :agents
    
      def initialize(data)
        @data = data
        @agents = []
        parse
      end
      
      def parse
        sections = @data.split(/^-+/)
        sections.delete_if do |section| section.chomp.empty? end
        if sections.length > 1
          sections[1..-2] = sections[1..-2].collect do |data|
            lines = data.split(/\n/)
            lines.delete_if do |ln| ln.chomp.empty? end
            result = [lines[0..-2].join("\n"), lines[-1]]
            result.delete_if do |ln| ln.chomp.empty? end
            result
          end
          sections.flatten!
          sections.collect! do |section| section.strip end
          
          if !sections.length.even?
            dump = sections.inspect          
            raise ParserException.new("Unexpected error parsing original data. Number of sections found is uneven. Expected format is agent name on one line, one or more hyphens on the next, then one or more lines of data. sections.inspect: <#{dump}>")
          end
          
          # sections should now alternate agent title and agent data
          while !sections.empty?
            agent_name_data, data = sections.shift, sections.shift
            agent_name, *reference_agent_names = agent_name_data.split(/(?=\()/)
            raise ParserException.new("Nested agents ( e.g. a(b(c)) ) not supported yet") if reference_agent_names.length > 1
            if reference_agent_names.length > 0
              reference_agent_names = reference_agent_names[0].gsub(/\(|\)/, '').split(/,/)
              reference_agent_names.collect! do |name| name.strip end
            else
              reference_agent_names = []
            end

            [agent_name, reference_agent_names].flatten.each do |a_name|            
              raise ParserException.new("Unregistered agent <#{a_name}> in agent name data <#{agent_name_data}>") if !Agents.instance.id_registered?(a_name)
            end
            
            reference_agents = []
            reference_agent_names.each do |ref_name|
              @agents.each do |agent|
                reference_agents << agent if agent.class.agent_id =~ /#{ref_name}/i
              end
            end
            agent_class = Agents.instance.get_agent_by_id(agent_name)
            @agents << agent_class.new(data, reference_agents)
          end
        end
        
      end
    end
    
    class CaseGen
      def CaseGen.version
        "1.1.0"
      end
    
      def initialize(data)
        load_agents
        Parser.new(data)
      end

      def load_agents
        agent_dir = "#{File.dirname(__FILE__)}/agents"
        agent_fns = Dir[File.join(agent_dir, '*.rb')]
        agent_fns.each do |fn| require fn end
        ObjectSpace.each_object(Class) do |klass|
          if klass.ancestors.include?(Agent) && (klass != Agent)
            Agents.instance.register(klass)  
          end
        end        
      end
    end
    
    class Console
      def initialize
        put_banner
      
        if ARGV[0].nil? || !File.exists?(ARGV[0])
          puts "Case file required: #{File.basename(__FILE__)} [case filename]. For example:"
          puts "  #{File.basename(__FILE__)} cases.txt"
          puts
          exit
        end

        CaseGen.new(File.read(ARGV[0]))
      end
      
      def put_banner
        $stderr.puts "cLabs Casegen #{CaseGen.version}"
      end
    end
  end
end

if __FILE__ == $0
  CLabs::CaseGen::Console.new
end