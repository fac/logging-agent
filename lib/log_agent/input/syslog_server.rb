module LogAgent::Input
  class SyslogServer < Base

    SEVERITY = {
      0 => 'emergency',
      1 => 'alert',
      2 => 'critical',
      3 => 'error',
      4 => 'warning',
      5 => 'notice',
      6 => 'informational',
      7 => 'debug'
    }.freeze

    attr_accessor :tags

    # Ref: http://tools.ietf.org/html/rfc5424#page-8
    module SyslogSocket
      attr_accessor :server
      def receive_data( datagram )
        server.emit server.parse(datagram)
      end
    end

    def parse( message )
      params = {
        :type   => 'syslog',
        :source_type => 'syslog',
        :tags => self.tags.dup,
        :fields => {}
      }

      if message =~ /^<(\d+)>(.*)$/
        prival = $1.to_i
        message = $2

        params[:fields].merge!({
          'syslog_version'    => 1,
          'syslog_severity'   => SEVERITY[prival % 8],
          'syslog_facility'   => prival / 8,
        })

        if message =~ /^1 ([^\s]+) ([^\s]+) ([^\s]+) ([^\s]+) ([^\s]+) (.*)$/
          params[:timestamp] = Time.parse($1)
          params[:fields].merge!({
            'syslog_hostname'   => ($2 == '-' ? nil : $2),
            'syslog_app_name'   => ($3 == '-' ? nil : $3),
            'syslog_proc_id'    => ($4 == '-' ? nil : $4),
            'syslog_msg_id'     => ($5 == '-' ? nil : $5),
            'syslog_app_string' => [$3, $4 == '-' ? "" : "[#{$4}]"].join(''),
            'syslog_timestamp'  => params[:timestamp].utc.strftime('%b %d %H:%M:%S'),
            'syslog_message'    => $6
          })

          if params[:fields]['syslog_message'] =~ /^- (.*)$/
            params[:fields]['syslog_message'] = $1
          end

          params[:message_format] = '%{syslog_timestamp} %{syslog_hostname} %{syslog_app_string}: %{syslog_message}'

        elsif message =~ /^([^\s]+)\s+(\d{1,2}) (\d{2}):(\d{2}):(\d{2}) ([^\s]+) ([^\s\[]+)(?:\[([^\]]+)\])?: (.*)$/
          params[:timestamp] = Time.utc(Time.now.year, $1, $2, $3, $4, $5)

          params[:fields].merge!({
            'syslog_hostname'   => ($6 == '-' ? nil : $6),
            'syslog_app_name'   => ($7 == '-' ? nil : $7),
            'syslog_proc_id'    => ($8 == '-' ? nil : $8),
            'syslog_timestamp'  => params[:timestamp].strftime('%b %d %H:%M:%S'),
            'syslog_message'    => $9
          })
        end
      end

      if params[:message].nil?
        params[:message] = message
      end

      LogAgent::Event.new(params)
    end

    def initialize sink, opts={}
      super sink
      @tags = opts[:tags] || []
      @listen = opts[:listen] || '127.0.0.1'
      @port = opts[:port] || raise("Must specify listen port for SyslogServer")
      @socket = EM.open_datagram_socket(@listen, @port, SyslogSocket ) {
        succeed
      }
      @socket.server = self
    end
  end

end