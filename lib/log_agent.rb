require 'amqp'
require 'json'
require 'eventmachine'
require 'logger'
require 'log_agent/version'
require 'time'
require 'socket'

module LogAgent
  autoload 'Event',        'log_agent/event'

  module Input
    autoload 'Base',         'log_agent/input/base'
    autoload 'FileTail',     'log_agent/input/file_tail'
    autoload 'SyslogServer', 'log_agent/input/syslog_server'
    autoload 'AMQP',         'log_agent/input/amqp'
  end
  module Filter
    autoload 'Base',                  'log_agent/filter/base'
    autoload 'Grep',                  'log_agent/filter/grep'
    autoload 'MultilineMessage',      'log_agent/filter/multiline_message'
    autoload 'Rails',                 'log_agent/filter/rails'
    autoload 'Barnyard',              'log_agent/filter/barnyard'
    autoload 'Ossec',                 'log_agent/filter/ossec'
    autoload 'PtDeadlock',            'log_agent/filter/pt_deadlock'
    autoload 'RubyLogFormatter',      'log_agent/filter/ruby_log_formatter'
    autoload 'RailsMultilineMessage', 'log_agent/filter/rails_multiline_message'
    autoload 'PidDemuxer',            'log_agent/filter/pid_demuxer'
    autoload 'RailsLogTagParser',     'log_agent/filter/rails_log_tag_parser'
    autoload 'MysqlSlow',             'log_agent/filter/mysql_slow'
  end
  module Output
    autoload 'ElasticsearchRiver', 'log_agent/output/elasticsearch_river'
    autoload 'AMQP',               'log_agent/output/amqp'
    autoload 'Debug',              'log_agent/output/debug'
  end

  module LogHelper
    def debug *args
      LogAgent.logger.debug(["[#{self.class}] ", *args].flatten.join(""))
    end
    def info *args
      LogAgent.logger.info(["[#{self.class}] ", *args].flatten.join(""))
    end
    def warn *args
      LogAgent.logger.warn(["[#{self.class}] ", *args].flatten.join(""))
    end
    def error *args
      LogAgent.logger.error(["[#{self.class}] ", *args].flatten.join(""))
    end
    def fatal *args
      LogAgent.logger.fatal(["[#{self.class}] ", *args].flatten.join(""))
    end
  end

  def self.logger
    @logger ||= Logger.new($stderr).tap { |logger|
      logger.level = !!ENV['DEBUG'] ? Logger::DEBUG : Logger::INFO
    }
  end

  # Allows the value of source_host set in locally generated events to be configured externally, rather than relying
  # on Socket.gethostname
  def self.hostname=(new_value)
    @hostname = new_value
  end
  def self.hostname
    @hostname || Socket.gethostname
  end
end
