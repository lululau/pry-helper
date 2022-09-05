require_relative 'lib/pry-helper/version'

Gem::Specification.new do |spec|
  spec.name          = "pry-helper"
  spec.version       = PryHelper::VERSION
  spec.authors       = ["Liu Xiang"]
  spec.email         = ["liuxiang921@gmail.com"]

  spec.summary       = %{Pry helpers}
  spec.description   = %{Pry helpers}
  spec.homepage      = "https://github.com/lululau/pry-helper"
  spec.license       = "MIT"
  spec.required_ruby_version = Gem::Requirement.new(">= 2.6.0")



  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files         = Dir.chdir(File.expand_path('..', __FILE__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.require_paths = ["lib"]

  spec.add_dependency 'activerecord'
  spec.add_dependency 'activesupport'
  spec.add_dependency 'pry-doc'
  spec.add_dependency 'rainbow'
  spec.add_dependency 'terminal-table'
  spec.add_dependency 'table_print'
  spec.add_dependency 'roo'
  spec.add_dependency 'caxlsx'
end
