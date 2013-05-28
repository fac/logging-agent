module LogAgent::Filter

  class PidDemuxer

    # Public: Create the demuxer. 
    #
    #   chain_block_val - this is passed to the chain creation block as the second argument
    #   options         - optional parameters for the filter:
    #       :timeout    - the length of time a PID object will last, unused, before it is released
    #
    #   &chain_block    - this block is called for each new pid, and the returned object used as the sink
    #                     for the pid.
    #       arg0  - the pid being created
    #       arg1  - the chain_block_val passed into the new call
    #      
    def initialize(chain_block_val, options = {}, &chain_block)
      @chain_block_val = chain_block_val
      @chain_block = chain_block
      @pid_timeout = options.fetch(:timeout, 60)

      @pid_last_used = {}
      @pid_objects = {}
      @last_pid = nil
    end

    # Public: The pid-timeout value, i.e. the length of time a pid-sink will exist without receiving events before it is 
    #    allowed to be garbage-collected.
    attr_reader :pid_timeout
    
    # Private: Returns the chain object for a given PID value. This will memoize
    #    the returned chain object, so can be called frequently, and the creation block
    #    will only be called when necessary
    #
    #   pid - the pid value
    #
    # Returns a "sink" object, or nil
    #
    def chain_for_pid(pid)
      @pid_last_used[pid] = Time.now

      @pid_last_used.each_pair do |pid, last_used|
        if last_used < Time.now - @pid_timeout
          @pid_last_used.delete(pid)
          @pid_objects.delete(pid)
        end
      end      
      @pid_objects[pid] ||= @chain_block.call(pid, @chain_block_val)
    end

    # Public: The sink method, to receive events.
    def << event
      pid = event.fields['pid']

      sink = chain_for_pid(pid || @last_pid)
      sink && sink << event
      @last_pid = pid
    end

  end

end