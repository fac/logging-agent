#!/usr/bin/env gem build

$:.push File.expand_path("../lib", __FILE__)
require "log_agent/version"

Gem::Specification.new do |s|
  s.name        = "log_agent"
  s.version     = LogAgent::VERSION
  s.authors     = ["Thomas Haggett"]
  s.email       = ["thomas@haggett.org"]
  s.homepage    = "http://engineering.freeagent.com/"
  s.summary     = %q{Shipping logs}
  s.description = %q{Fills in the gaps between the clever parts of our log-shipping architecture.}

  s.files         = `git ls-files`.split($\)
  s.executables   = s.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  s.test_files    = s.files.grep(%r{^(test|spec|features)/})
  s.require_paths = ["lib"]

  s.add_runtime_dependency 'eventmachine', '~> 0.12.10'
  s.add_runtime_dependency 'amqp', '~> 1.5.0'
  s.add_runtime_dependency 'uuid', '~> 2.3.5'
  s.add_runtime_dependency 'json', '~> 1.5.4'
  s.add_runtime_dependency 'daemons', '~> 1.1.8'
  s.add_runtime_dependency 'eventmachine-tail', '~> 0.6.3'
  s.add_runtime_dependency 'amq-protocol', '1.9.2'

  s.add_development_dependency 'rspec'
  s.add_development_dependency 'evented-spec'
  s.add_development_dependency 'timecop'
end
