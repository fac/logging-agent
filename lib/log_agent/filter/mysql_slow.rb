require 'time'
require 'digest/md5'
require 'strscan'

module LogAgent::Filter
  class MysqlSlow < Base

    include LogAgent::LogHelper

    IGNORE_MATCHES = [
      # Ignore the header at the start of the file
      /.+, Version: .+ started with\:$/,
      /^Tcp port\: .+ Unix socket\:/,
      /^Time\s+Id\s+Command\s+Argument$/,
    ]

    attr_reader :limit

    # Creates the slow query logger with given options:
    #
    #   limit - any line longer than this limit is truncated to prevent
    #           loading mysqldumps to be dumped into the logs!
    #           defaults to 1024 bytes
    #
    def initialize sink, options = {}
      @options = options
      @limit = options.fetch(:limit, 20 * 1024)
      @events = []
      @scanner = StringScanner.new("")
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

    def truncate_message(event)
      # Truncate the message if necessary
      if event.message.size > @limit
        event.fields['truncated'] = true
        event.fields['original_length'] = event.message.size
        event.message = event.message.slice(0, @limit)
      end
    end

    def parse_comment(message)
      # ... but pick out metadata if we understand it
      if message =~ /^# Time: (.*)$/
        @timestamp = Time.parse($1).utc rescue nil
      end

      if message =~ /^#\s+Query_time:\s+([\d.]+)\s+Lock_time:\s+([\d.]+)\s+Rows_sent:\s+(\d+)\s+Rows_examined:\s+(\d+)$/
        @query_data = { "time" => $1.to_f, "lock_time" => $2.to_f, "rows_sent" => $3.to_i, "rows_examined" => $4.to_i }
      end

      if message =~ /^# User@Host: (.*)\[(.*)\] @  \[(.*)\]$/
        @connection_data = { "user" => $1, "system_user" => $2, "host" => $3 }
      end
    end

    # Buffered tokenizer, but working with events!
    #
    # Pro-tip (?=<blah) is a look-ahead match, so it checks that it's a
    # new-line, followed by a comment, without actually eating the comment
    # marker itself.
    DELIMITER = /(.+;\n|^#.+\n|.+\n(?=#))/m
    def extract(event)

      # Argh, events are line-oriented and get chomped, but we need  different multi-line matches, o
      # so lets add a newline back in!
      event.message = "#{event.message}\n"
      @events << event
      @scanner.concat(event.message)

      while match = @scanner.scan(DELIMITER)

        event = if match == @scanner.string and match == event.message
          event.tap { |e| e.message.chomp! }
        else
          LogAgent::Event.reduce(@events).tap { |e| e.message = match.chomp }
        end

        yield(event)

        @events = []
      end
    end

    def << event
      # Skip lines that match the ignore matches
      return if IGNORE_MATCHES.find { |r| event.message =~ r }

      extract(event) do |event|

        truncate_message(event)

        # Ignore comments ...
        if event.message =~ /^#/
          parse_comment(event.message)

        elsif event.message =~ /^set timestamp=(\d+);$/i
          # Manually handle SET timestamp=<\d> messages
          @timestamp = Time.at($1.to_i)

        # ignore use ...; statements, but grab the database
        elsif event.message =~ /^use (.*);$/i
          @database = $1

        elsif event.message =~ /^set timestamp=(\d+);$/i
          # Manually handle SET timestamp=<\d> messages
          @timestamp = Time.at($1.to_i)

        else
          if @query_data
            event.fields['query'] = @query_data
            @query_data = nil
          end

          event.timestamp = @timestamp if @timestamp
          event.fields['connection'] = @connection_data if @connection_data
          event.fields['database'] = @database if @database
          event.fields['fingerprint'] = Digest::MD5.hexdigest(fingerprint(event.message)) unless event.fields['truncated']

          emit(event)
        end
      end
    end
  end
end
