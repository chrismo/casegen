require 'bundler/gem_tasks'

require 'rake/testtask'

desc 'Run tests'
Rake::TestTask.new do |t|
  t.pattern = 'test/**/*test*.rb'
  # t.verbose = true
end

task default: :test