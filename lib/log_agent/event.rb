require 'uuid'

module LogAgent
  class Event
    include LogAgent::LogHelper

    attr_reader :source_type, :source_host, :source_path, :uuid
    attr_accessor :tags, :fields
    attr_accessor :type, :message, :message_format, :timestamp, :captured_at

    def self.reduce(events, &reducer)
      reducer ||= lambda do |messages|
        messages.join("\n")
      end

      first_event = events.first
      LogAgent::Event.new({
        :uuid        => first_event.uuid,
        :source_host => first_event.source_host,
        :source_type => first_event.source_type,
        :source_path => first_event.source_path,
        :tags        => first_event.tags,
        :type        => first_event.type,
        :timestamp   => first_event.timestamp,
        :message     => reducer.call(events.map { |e| e.message }),
        :fields      => events.inject({}) { |out,event| out.merge!(event.fields) }
      })
    end


    def initialize opts={}
      @captured_at = opts[:captured_at] || Time.now
      @uuid = opts[:uuid] || UUID.generate
      @type = opts[:type] || ""
      @source_type = opts[:source_type] || ""
      @source_host = opts[:source_host] || LogAgent.hostname
      @source_path = opts[:source_path] || ""
      @tags = opts[:tags] || []
      @message = opts[:message] || ""
      @message_format = opts[:message_format] || nil
      @timestamp = opts[:timestamp] || Time.now
      @fields = opts[:fields] || {}
      debug "Event '#{@uuid}' created"
    end

    def message_format= new_format
      @message_format = new_format
    end

    def message
      if @message_format
        @message_format.dup.tap do |message|
          message.gsub!('%{@timestamp}') { self.timestamp.iso8601(6) }
          @fields.each_pair do |key, value|
            message.gsub! "%{#{key}}", value.to_s
          end
          message.gsub!(/%{@tags:?(.*)}/) { |m| m =~ /%{@tags(:?)(.*)}/ && self.tags.join($1==":" ? $2 : " ") }
          message.gsub!('%{@source_type}', self.source_type)
          message.gsub!('%{@source_host}', self.source_host)
          message.gsub!('%{@source_path}', self.source_path)
          message.gsub!('%{@type}', self.type)
          message.gsub!('%{@uuid}', self.uuid)
        end
      else
        @message
      end
    end

    def message= new_message
      raise RuntimeError, "message is immutable when message_format is set" if @message_format
      @message = new_message
    end

    def to_payload
      debug "Dumping event '#{@uuid}' to payload:"
      JSON.dump({
        '@timestamp'    => self.timestamp.iso8601(6),
        '@captured_at'  => self.captured_at.iso8601(6),
        '@source_type'  => self.source_type,
        '@source_host'  => self.source_host,
        '@source_path'  => self.source_path,
        '@fields'       => self.fields,
        '@message'      => self.message,
        '@tags'         => self.tags,
        '@type'         => self.type,
        '@uuid'         => self.uuid
      }).tap { |json| debug json }
    end

    def self.from_payload(json)
      data = JSON.load(json)
      new({
        :timestamp    => (Time.parse(data['@timestamp']) rescue nil),
        :captured_at  => (Time.parse(data['@captured_at']) rescue nil),
        :source_host  => data['@source_host'],
        :source_path  => data['@source_path'],
        :source_type  => data['@source_type'],
        :fields       => data['@fields'],
        :message      => data['@message'],
        :tags         => data['@tags'],
        :type         => data['@type'],
        :uuid         => data['@uuid']
      }).tap { |event| LogAgent.logger.debug "[Event] Loaded event '#{event.uuid}' object from json: #{json}" }
    end
  end
end