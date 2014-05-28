require File.expand_path('../src/casegen', __FILE__)

Gem::Specification.new do |s|
  s.name = 'casegen'
  s.version = CLabs::CaseGen::CaseGen.version
  s.summary = 'Simple Ruby DSL to generate use cases restricted by sets of rules'
  s.authors = ['chrismo']
  s.email = 'chrismo@clabs.org'
  s.files = Dir["src/**/*"]
  s.require_path = 'src'
  s.executables = 'casegen'
  s.homepage = 'https://github.com/chrismo/casegen'
  s.license = 'BSD'
end
