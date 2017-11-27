lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

Gem::Specification.new do |spec|
  spec.name          = "can-do"
  spec.version       = "1.1.2"
  spec.authors       = ["Blacklane"]

  spec.summary       = %q{Simple feature flags.}
  spec.description   = %q{Simple feature flags based on a redis instance, a YAML config file and/or environment variables.}
  spec.homepage      = "https://github.com/blacklane/can-do"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "redis"
  spec.add_dependency "connection_pool"

  spec.add_development_dependency "bundler"
  spec.add_development_dependency "pry"
  spec.add_development_dependency "rspec"
  spec.add_development_dependency "rubocop"
  spec.add_development_dependency "rspec-mocks"
end
