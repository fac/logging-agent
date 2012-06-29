module LogAgent::Filter
  class MultilineMessage < Base
    include LogAgent::LogHelper
    
    attr_reader :options
    def initialize sink, options = {}
      @options = options
      @start = options[:start]
      @end = options[:end]
      @buffer = nil
      super(sink)
    end

    def << event
      debug "Received event '#{event.uuid}'"
      if @buffer.nil? && event.message =~ @start
        debug "Start token encountered. Open buffer."
        @buffer = []
      end

      if @buffer
        debug "Adding event '#{event.uuid}' to the buffer"
        @buffer << event
        
        if event.message =~ @end
          debug "End token reached in event '#{event.uuid}'. Reducing."
          event = reduce(@buffer)
          debug "Generated aggregate event '#{event.uuid}'"
          @buffer = nil
        else
          event = nil
        end
      end
      
      if event
        debug "Emitting '#{event.uuid}'" 
        emit event
      end
    end
    
    def reduce events
      first_event = events.first
      LogAgent::Event.new({
        :uuid        => first_event.uuid,
        :source_host => first_event.source_host,
        :source_type => first_event.source_type, 
        :source_path => first_event.source_path,
        :tags        => first_event.tags,
        :type        => first_event.type,
        :timestamp   => first_event.timestamp,
        :message     => events.collect { |event| event.message }.join("\n"),
        
      })
    end
  end
end