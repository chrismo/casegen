# frozen_string_literal: true

require_relative 'lib/casegen'

Gem::Specification.new do |gem|
  gem.name = 'casegen'
  gem.version = '3.0.0'
  gem.authors = ['chrismo']
  gem.email = 'chrismo@clabs.org'
  gem.description = 'Simple tool to generate use cases restricted by sets of rules'
  gem.summary = 'Simple tool to generate use cases restricted by sets of rules'
  gem.homepage = 'https://github.com/chrismo/casegen'
  gem.license = 'MIT'

  gem.files         = `git ls-files`.split($INPUT_RECORD_SEPARATOR)
  gem.executables   = 'casegen'
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ['lib']

  gem.required_ruby_version = '~> 2.5'

  gem.add_dependency 'tablesmith'

  gem.add_development_dependency 'rake'
  gem.add_development_dependency 'rspec'
  gem.add_development_dependency 'rubocop'
  gem.add_development_dependency 'rubocop-performance'
  gem.add_development_dependency 'rubocop-rake'
  gem.add_development_dependency 'rubocop-rspec'
end
