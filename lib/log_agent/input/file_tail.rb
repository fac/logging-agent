require 'eventmachine-tail'

module LogAgent::Input
  class FileTail < Base
    include LogAgent::LogHelper
    
    attr_accessor :format, :type, :message_format
    attr_reader :path, :tags

    def initialize sink, opts={}
      super sink

      @path = opts[:path] || raise(ArgumentError, ":path option is required for FileTail")
      @tags = opts[:tags] || []
      @format = opts[:format] || :text
      @type = opts[:type] || ''
      @message_format = opts[:message_format] || nil
      EventMachine::FileGlobWatchTail.new(path, &method(:handle_event))
      debug "Watching paths: #{path}"

      self.succeed
    end

    def handle_event file, line
      debug "File(#{file.path}) emitted line: '#{line}'"

      # Have a first stab at parsing the JSON-event if we're marked as that type
      event = if format.to_s == 'json_event'
        debug "Decoding Event object."
        begin
          LogAgent::Event.from_payload(line)
        rescue
          LogAgent.logger.warn("Failed to parse JSON-Event line from file: '#{file.path}': #{$!.message}")
          nil
        end
      end

      if event.nil?
        params = {
          :message        => line,
          :source_type    => 'file',
          :source_path    => file.path,
          :tags           => self.tags.dup,
          :type           => self.type
        }
      
        if format.to_s == 'json'
          debug "Parsing JSON"
          begin
            params[:fields] = JSON.load(line)
            params[:message_format] = self.message_format
            params[:message] = nil
          rescue
            LogAgent.logger.warn("Failed to parse JSON line from file: '#{file.path}': #{$!.message}")
          end
        end
        event = LogAgent::Event.new(params)        
      end

      if event 
        debug "Emitting event '#{event.uuid}'"
        emit event
      end
    end
  end
end