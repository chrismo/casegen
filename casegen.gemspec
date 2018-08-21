lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'casegen'

Gem::Specification.new do |gem|
  gem.name = 'casegen'
  gem.version = CLabs::CaseGen::CaseGen.version
  gem.authors = ['chrismo']
  gem.email = 'chrismo@clabs.org'
  gem.description = 'Simple Ruby DSL to generate use cases restricted by sets of rules'
  gem.summary = 'Simple Ruby DSL to generate use cases restricted by sets of rules'
  gem.homepage = 'https://github.com/chrismo/casegen'
  gem.license = 'MIT'

  gem.files         = `git ls-files`.split($/)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ['lib']

  gem.add_dependency 'tablesmith'

  gem.add_development_dependency 'minitest'
  gem.add_development_dependency 'rake'
end
