module LogAgent::Filter


  # This is a specific Rails multiline message filter, building on the 
  class RailsMultilineMessage < MultilineMessage

    class RequestState
      attr_reader :request_id
      attr_reader :events, :message_length
      def initialize(filter, request_id, &emit_block)
        @request_id = request_id
        @emit_block = emit_block
        @events = []
        @filter = filter
        @message_length = 0
        reset_timer
      end
      def << event
        reset_timer
        @message_length += event.message.size
        @events << event
      end
      def emit! reason=nil
        cancel_timer
        @emit_block.call reason
      end
    private
      def cancel_timer
        @timer && EventMachine.cancel_timer(@timer)  
      end
      def reset_timer
        if @filter.max_time
          cancel_timer
          @timer = EventMachine.add_timer(@filter.max_time) { emit! :timer_fired! }
        end
      end
    end

    attr_reader :max_time, :max_size

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
    def initialize(chain, request_id_tag='req', max_time=60, max_size=10 * 1024)
      @request_id_tag = request_id_tag
      @max_size = max_size
      @max_time = max_time

      @pids = {}
      super(chain, :start => /^Started /, :end => /^Completed /, :max => max_size )
    end

    def << event

      pid = event.fields['pid']

      request_id, event.message = if event.message =~ /^\s*\[#{@request_id_tag}=([^\]]+)\] (.+)$/
        [$1, $2]
      else
        [nil, event.message]
      end

      if @pids[pid] 

        if @pids[pid].request_id != request_id
          @pids[pid].emit! :next_request
        end
      else
        @pids[pid] ||= RequestState.new(self, request_id) do |reason|
          # this gets called either when #emit! is called directly, or
          # when the idle timer, or max-size counter fire.
          reduce_and_emit(@pids.delete(pid))
        end
      end

      @pids[pid] && @pids[pid] << event

      if (@pids[pid] && @pids[pid].message_length > @max_size) || event.message =~ /^Completed /
        @pids[pid].emit! :completed_matched
      end
    end

    def reduce_and_emit(state)
      event = reduce(state.events)
      event.fields['rails_request_id'] = state.request_id
      emit(event)
    end

  end
end