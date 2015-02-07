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
          event = LogAgent::Event.reduce(@buffer)
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
  end
end