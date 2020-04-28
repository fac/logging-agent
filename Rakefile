#!/usr/bin/env rake
require "bundler/gem_tasks"

begin
  require 'rspec/core/rake_task'
  spec_task = RSpec::Core::RakeTask.new(:spec)
  spec_task.pattern = "spec/unit"
  task :default => :spec
rescue LoadError
  # no rspec available
end
