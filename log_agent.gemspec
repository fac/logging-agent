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

  s.files         = %w{
    README.md
    bin/logagentctl
    bin/logagentd
    lib/log_agent.rb
    lib/log_agent/event.rb
    lib/log_agent/filter/ossec.rb
    lib/log_agent/filter/barnyard.rb
    lib/log_agent/filter/base.rb
    lib/log_agent/filter/grep.rb
    lib/log_agent/filter/multiline_message.rb
    lib/log_agent/filter/pt_deadlock.rb
    lib/log_agent/filter/rails.rb
    lib/log_agent/filter/ruby_log_formatter.rb
    lib/log_agent/filter/rails_multiline_message.rb
    lib/log_agent/filter/pid_demuxer.rb
    lib/log_agent/input/amqp.rb
    lib/log_agent/input/base.rb
    lib/log_agent/input/file_tail.rb
    lib/log_agent/input/syslog_server.rb
    lib/log_agent/output/amqp.rb
    lib/log_agent/output/debug.rb
    lib/log_agent/output/elasticsearch_river.rb
    lib/log_agent/version.rb
    log_agent.gemspec
    spec/data/logstash-event.json
    spec/data/barnyard_entries/entry1.log
    spec/data/barnyard_entries/entry2.log
    spec/data/barnyard_entries/entry3.log
    spec/data/barnyard_entries/entry4.log
    spec/data/barnyard_entries/entry5.log
    spec/data/rails_entries/entry1.log
    spec/data/rails_entries/entry2.log
    spec/data/rails_entries/entry3.log
    spec/data/rails_entries/entry4.log
    spec/data/rails_entries/entry5.log
    spec/data/rails_entries/entry6.log
    spec/data/ruby_log_formatter_entries/entry1.log
    spec/data/pt_deadlock_entries/entry1.log
    spec/data/pt_deadlock_entries/entry2.log
    spec/data/ossec_entries/entry1.log
    spec/data/ossec_entries/entry2.log
    spec/functional/filter/barnyard_spec.rb
    spec/functional/filter/ossec_spec.rb
    spec/functional/filter/base_spec.rb
    spec/functional/filter/grep_spec.rb
    spec/functional/filter/multiline_message_spec.rb
    spec/functional/filter/rails_spec.rb
    spec/functional/filter/ruby_log_formatter_spec.rb
    spec/functional/filter/rails_multiline_message_spec.rb
    spec/functional/filter/pid_demuxer_spec.rb
    spec/functional/filter/pt_deadlock_spec.rb
    spec/functional/input/amqp_spec.rb
    spec/functional/input/base_spec.rb
    spec/functional/input/file_tail_spec.rb
    spec/functional/input/syslog_server_spec.rb
    spec/functional/output/amqp_spec.rb
    spec/functional/output/elasticsearch_river_spec.rb
    spec/integration/log_indexing_spec.rb
    spec/spec_helper.rb
    spec/unit/event_spec.rb
  }
  s.test_files    = %w{
    spec/data/logstash-event.json
    spec/data/barnyard_entries/entry1.log
    spec/data/barnyard_entries/entry2.log
    spec/data/barnyard_entries/entry3.log
    spec/data/barnyard_entries/entry4.log
    spec/data/barnyard_entries/entry5.log
    spec/data/rails_entries/entry1.log
    spec/data/rails_entries/entry2.log
    spec/data/rails_entries/entry3.log
    spec/data/rails_entries/entry4.log
    spec/data/rails_entries/entry5.log
    spec/data/rails_entries/entry6.log
    spec/data/ruby_log_formatter_entries/entry1.log
    spec/data/ossec_entries/entry1.log
    spec/data/ossec_entries/entry2.log
    spec/data/pt_deadlock_entries/entry1.log
    spec/data/pt_deadlock_entries/entry2.log
    spec/functional/filter/barnyard_spec.rb
    spec/functional/filter/ossec_spec.rb
    spec/functional/filter/base_spec.rb
    spec/functional/filter/grep_spec.rb
    spec/functional/filter/multiline_message_spec.rb
    spec/functional/filter/rails_spec.rb
    spec/functional/filter/ruby_log_formatter_spec.rb
    spec/functional/filter/pt_deadlock_spec.rb
    spec/functional/filter/rails_multiline_message_spec.rb
    spec/functional/filter/pid_demuxer_spec.rb
    spec/functional/input/amqp_spec.rb
    spec/functional/input/base_spec.rb
    spec/functional/input/file_tail_spec.rb
    spec/functional/input/syslog_server_spec.rb
    spec/functional/output/amqp_spec.rb
    spec/functional/output/elasticsearch_river_spec.rb
    spec/integration/log_indexing_spec.rb
    spec/spec_helper.rb
    spec/unit/event_spec.rb
  }
  s.executables   = %w{
    logagentctl
    logagentd
  }
  s.require_paths = ["lib"]

  s.add_runtime_dependency 'eventmachine'
  s.add_runtime_dependency 'amqp'
  s.add_runtime_dependency 'uuid'
  s.add_runtime_dependency 'json'
  s.add_runtime_dependency 'daemons'
  s.add_runtime_dependency 'eventmachine-tail'
  
  s.add_development_dependency 'rspec'
  s.add_development_dependency 'evented-spec'
  s.add_development_dependency 'timecop'
end

