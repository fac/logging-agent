require 'time'
module LogAgent::Filter
  class MysqlSlow < Base

    include LogAgent::LogHelper

    def initialize sink
      @timestamp = Time.now.utc
      @event = {}
      super sink
    end

    def << event
      if event.message =~ /^# Time: (\d+ \d\d:\d\d:\d\d)$/
        @timestamp = Time.parse($1).utc rescue Time.now.utc
        debug "Timestamp is #{@timestamp}"
      end

      if event.message =~ /^# User@Host: .*\[(.*)\] @  \[(.*)\]$/
        @event['mysql_slow_user'] = $1
        @event['mysql_slow_ip'] = $2
      end

      if event.message =~ /^# Query_time: (\d+)  Lock_time: (\d+)  Rows_sent: (\d+)  Rows_examined: (\d+)$/
        @event['mysql_slow_query_time'] = $1.to_i
        @event['mysql_slow_lock_time'] = $2.to_i
        @event['mysql_slow_rows_sent'] = $3.to_i
        @event['mysql_slow_rows_examined'] = $4.to_i
      end

      if event.message =~ /^([^#].*)$/
        event.timestamp = @timestamp
        event.fields.merge! @event
        emit event
      end
    end
  end
end
