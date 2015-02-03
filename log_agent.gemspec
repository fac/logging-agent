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

  # Regenerate this using
  # git ls-files
  s.files         = %w{
    README.md
    TODOS.md
    bin/logagentctl
    bin/logagentd
    lib/log_agent.rb
    lib/log_agent/event.rb
    lib/log_agent/filter/barnyard.rb
    lib/log_agent/filter/base.rb
    lib/log_agent/filter/grep.rb
    lib/log_agent/filter/multiline_message.rb
    lib/log_agent/filter/mysql_slow.rb
    lib/log_agent/filter/ossec.rb
    lib/log_agent/filter/pid_demuxer.rb
    lib/log_agent/filter/pt_deadlock.rb
    lib/log_agent/filter/rails.rb
    lib/log_agent/filter/rails_log_tag_parser.rb
    lib/log_agent/filter/rails_multiline_message.rb
    lib/log_agent/filter/ruby_log_formatter.rb
    lib/log_agent/input/amqp.rb
    lib/log_agent/input/base.rb
    lib/log_agent/input/file_tail.rb
    lib/log_agent/input/syslog_server.rb
    lib/log_agent/output/amqp.rb
    lib/log_agent/output/debug.rb
    lib/log_agent/output/elasticsearch_river.rb
    lib/log_agent/version.rb
    log_agent.gemspec
    spec/data/barnyard_entries/entry1.log
    spec/data/barnyard_entries/entry2.log
    spec/data/barnyard_entries/entry3.log
    spec/data/barnyard_entries/entry4.log
    spec/data/barnyard_entries/entry5.log
    spec/data/logstash-event.json
    spec/data/mysql_slow_entries/entry1.log
    spec/data/mysql_slow_entries/entry2.log
    spec/data/mysql_slow_entries/entry3.log
    spec/data/ossec_entries/entry1.log
    spec/data/ossec_entries/entry2.log
    spec/data/pt_deadlock_entries/entry1.log
    spec/data/pt_deadlock_entries/entry2.log
    spec/data/rails_entries/entry1.log
    spec/data/rails_entries/entry2.log
    spec/data/rails_entries/entry3.log
    spec/data/rails_entries/entry4.log
    spec/data/rails_entries/entry5.log
    spec/data/rails_entries/entry6.log
    spec/data/rails_entries/entry7.log
    spec/data/rails_multiline_message_entries/log_file1.log
    spec/data/ruby_log_formatter_entries/entry1.log
    spec/data/ruby_log_formatter_entries/entry2.log
    spec/data/ruby_log_formatter_entries/entry3.log
    spec/functional/filter/barnyard_spec.rb
    spec/functional/filter/base_spec.rb
    spec/functional/filter/grep_spec.rb
    spec/functional/filter/multiline_message_spec.rb
    spec/functional/filter/mysql_slow_spec.rb
    spec/functional/filter/ossec_spec.rb
    spec/functional/filter/pid_demuxer_spec.rb
    spec/functional/filter/pt_deadlock_spec.rb
    spec/functional/filter/rails_log_tag_parser_spec.rb
    spec/functional/filter/rails_multiline_message_spec.rb
    spec/functional/filter/rails_spec.rb
    spec/functional/filter/ruby_log_formatter_spec.rb
    spec/functional/input/amqp_spec.rb
    spec/functional/input/base_spec.rb
    spec/functional/input/file_tail_spec.rb
    spec/functional/input/syslog_server_spec.rb
    spec/functional/output/amqp_spec.rb
    spec/functional/output/elasticsearch_river_spec.rb
    spec/integration/log_indexing_spec.rb
    spec/spec_helper.rb
    spec/support/fixtures.rb
    spec/support/time_helpers.rb
    spec/unit/event_spec.rb
    vendor/eventmachine-tail/README.textile
    vendor/eventmachine-tail/Rakefile
    vendor/eventmachine-tail/bin/emtail
    vendor/eventmachine-tail/bin/rtail
    vendor/eventmachine-tail/eventmachine-tail.gemspec
    vendor/eventmachine-tail/lib/em/filetail.rb
    vendor/eventmachine-tail/lib/em/globwatcher.rb
    vendor/eventmachine-tail/lib/eventmachine-tail.rb
    vendor/eventmachine-tail/samples/glob-tail.rb
    vendor/eventmachine-tail/samples/globwatch.rb
    vendor/eventmachine-tail/samples/tail-with-block.rb
    vendor/eventmachine-tail/samples/tail.rb
    vendor/eventmachine-tail/test/alltests.rb
    vendor/eventmachine-tail/test/test_filetail.rb
    vendor/eventmachine-tail/test/test_glob.rb
    vendor/eventmachine-tail/test/testcase_helpers.rb
  }
  s.test_files = s.files.select { |f| f =~ %r{^spec/} }
  s.executables = s.files.select { |f| f =~ %r{^bin/} }.map { |f| File.basename(f) }

  s.require_paths = ["lib", "vendor/eventmachine-tail/lib"]

  s.add_runtime_dependency 'eventmachine', '~> 0.12.10'
  s.add_runtime_dependency 'amqp', '~> 1.3'
  s.add_runtime_dependency 'uuid', '~> 2.3.5'
  s.add_runtime_dependency 'json', '~> 1.5.4'
  s.add_runtime_dependency 'daemons', '~> 1.1.8'

  s.add_development_dependency 'rspec'
  s.add_development_dependency 'evented-spec'
  s.add_development_dependency 'timecop'
end

