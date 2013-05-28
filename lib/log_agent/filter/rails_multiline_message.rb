module LogAgent::Filter


  # This is a specific Rails multiline message filter, building on the 
  class RailsMultilineMessage < MultilineMessage

    attr_reader :max_time, :max_size
    attr_reader :timer

    # Creates the filter
    #
    #   chain          - the next chain link to pass events to
    #   request_id_tag - the request_id tag used in the rails logs
    #   max_time       - how long to wait before considering a message finished
    #   max_size       - how many bytes to scrape until we presume we've messed up
    #
    # We emit logs using a rails tag, so log-entries should be prefixed with
    # something like [req=<request-id>]. In this case request_id_tag should be "req"
    #
    # This class will fall back on detecting /^Started / and /^Completed / for
    # rails hosts that don't log the request id
    #
    def initialize(chain, request_id_tag='req', max_time=60, max_size=100 * 1024)
      @request_id_tag = request_id_tag
      @max_size = max_size
      @max_time = max_time

      @current_request_id = nil

      @completed_match = /^Completed /
      super(chain, :start => /^Started /, :end => @completed_match, :max => max_size )
    end

    def << event
      request_id, event.message = if event.message =~ /^\s*\[#{@request_id_tag}=([^\]]+)\] (.*)$/
        [$1, $2]
      else
        [nil, event.message]
      end

      request_id = @current_request_id if request_id.nil? && !@current_request_id.nil?

      if request_id.nil?
        super(event)
      else
        if @current_request_id != request_id
          @event && emit(@event)
          @event = event
          @current_request_id = request_id
        else
          @event = reduce([@event, event])

          # Should we quit early?
          if event.message =~ @completed_match || @event.message.size >= max_size
            emit(@event)
            @event = nil
            @current_request_id = nil
          end
        end
      end
    end

    def emit(event)
      event.fields['request_id'] = @current_request_id
      super(event)
    end

  end
end