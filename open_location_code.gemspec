# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'open_location_code/version'

Gem::Specification.new do |spec|
  spec.name          = "open_location_code"
  spec.version       = OpenLocationCode::VERSION
  spec.authors       = ["Jiren"]
  spec.email         = ["jirenpatel@gmail.com"]

  spec.summary       = %q{TODO: Write a short summary, because Rubygems requires one.}
  spec.description   = %q{Open Location Codes are a way of encoding location into a form that is
  easier to use than latitude and longitude.}
  spec.homepage      = "https://github.com/jiren/open_location_code"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.9"
  spec.add_development_dependency "rake", "~> 10.0"
end
