require 'time'
require 'digest/md5'

module LogAgent::Filter
  class MysqlSlow < Base

    include LogAgent::LogHelper

    attr_reader :limit

    # Creates the slow query logger with given options:
    #
    #   limit - any line longer than this limit is truncated to prevent
    #           loading mysqldumps to be dumped into the logs!
    #           defaults to 1024 bytes
    #
    def initialize sink, options = {}
      @options = options
      @limit = options.fetch(:limit, 1024)
      @event = {}
      super sink
    end

    # Returns a generic "fingerprint" string for a given SQL query
    #
    # Shamelessly ported from pt-fingerprint / QueryReviewer's fingerprint(...) function
    def fingerprint(query)
      query = query.dup
      if query =~ %r[\ASELECT /\*!40001 SQL_NO_CACHE \*/ \* FROM]m
        'mysqldump'
      elsif query =~ %r[/\*\w+\.\w+:[0-9]/[0-9]\*/]m
        'percona-toolkit'
      elsif query =~ /\Aadministrator command: /m
        query
      elsif query =~ /\A\s*(call\s+\S+)\(/im
        $1.downcase
      elsif query =~ /\Ause \S+\Z/im
        "use ?"
      else
        query.gsub!(/;\s*\Z/, '')
        # oneline comments
        query.gsub!(/(?:--|#)[^'"\r\n]*(?=[\r\n]|\Z)/m, '')

        # multi-line comments
        query.gsub!(%r[/\*.*\*/]m, '') { |value| p value }

        # Quoted strings
        query.gsub!(/\\["']/m, '')
        query.gsub!(/".*?"/m, '?')
        query.gsub!(/'.*?'/m, '?')

        # Match numbers
        query.gsub!(/[0-9+-][0-9a-f.xb+-]*/, '?')
        query.gsub!(/[xb.+-]\?/, '?')

        query.gsub!(/\A\s+/, '')         # Chop off leading whitespace
        query.gsub!(/\s+\Z/, '')         # Kill trailing whitespace
        query.gsub!(/[\t\n\r]/, ' ')
        query.gsub!(/[\s\t\n\r]{2,}/m, ' ')       # Collapse whitespace
        query.downcase!
        query.gsub!(/\bnull\b/, '?')     # Get rid of NULLs

        # Collapse IN and VALUES lists
        query.gsub!(/\b(in|values?)(?:[\s,]*\([\s?,]*\))+/) { "#{$1}(?+)" }

        # Collapse UNION
        query.gsub!(/\b(select\s.*?)(?:(\sunion(?:\sall)?)\s\1)+/) { "#{$1} /*repeat#{$2}*/" }

        # Limit
        query.gsub!(/\blimit \?(?:, ?\?| offset \?)?/, 'limit ?')

        # Find, anchor on ORDER BY clause
        if query =~ /\bORDER BY /mi
          true while query.gsub!(/\G(.+?)\s+ASC/i) { $1 }
        end

        query
      end
    end

    def << event
      # Truncate the message if necessary
      if event.message.size > @limit
        event.fields['truncated'] = true
        event.fields['original_length'] = event.message.size
        event.message = event.message.slice(0, @limit)
      end

      # Ignore comments ...
      if event.message =~ /^#/
        # ... but pick out metadata if we understand it
        if event.message =~ /^# Time: (.*)$/
          @timestamp = Time.parse($1).utc rescue nil
        end

        if event.message =~ /^# Query_time: (\d+)  Lock_time: (\d+)  Rows_sent: (\d+)  Rows_examined: (\d+)$/
          @query_data = { "time" => $1.to_i, "lock_time" => $2.to_i, "rows_sent" => $3.to_i, "rows_examined" => $4.to_i }
        end

        if event.message =~ /^# User@Host: (.*)\[(.*)\] @  \[(.*)\]$/
          @connection_data = { "user" => $1, "system_user" => $2, "host" => $3 }
        end

      # ignore use ...; statements, but grab the database
      elsif event.message =~ /^use (.*);$/i
        @database = $1

      else
        if @timestamp
          event.timestamp = @timestamp
        end
        if @connection_data
          event.fields['connection'] = @connection_data
        end
        if @query_data
          event.fields['query'] = @query_data
          @query_data = nil
        end
        if @database
          event.fields['database'] = @database
        end

        event.fields['fingerprint'] = Digest::MD5.hexdigest(fingerprint(event.message))

        emit(event)
      end
    end
  end
end
