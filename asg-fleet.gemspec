# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
#require 'asg/fleet/version'

Gem::Specification.new do |spec|
  spec.name          = "aws-asg-fleet"
  spec.version       = "0.1.3"
  spec.authors       = ["Zach Wily"]
  spec.email         = ["zach@zwily.com"]
  spec.description   = %q{AWS Auto Scaling Fleets}
  spec.summary       = %q{Provides a mechanism to group together Auto Scaling groups and perform actions on them in bulk.}
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency "aws-sdk-autoscaling", "~> 1.3"

  spec.add_development_dependency "bundler", "~> 2.0"
  spec.add_development_dependency "rake"
end
