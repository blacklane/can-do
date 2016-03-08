lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

Gem::Specification.new do |spec|
  spec.name          = "can-do"
  spec.version       = "0.1.0"
  spec.authors       = ["Florin Lipan"]
  spec.email         = ["florin.lipan@blacklane.com"]

  spec.summary       = %q{Simple feature flags.}
  spec.description   = %q{Simple feature flags based on a YAML config file and/or environment variables.}
  spec.homepage      = "https://github.com/blacklane/can-do"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler"
end
