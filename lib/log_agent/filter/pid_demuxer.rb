module LogAgent::Filter

  class PidDemuxer

    def initialize(chain_block_val, &chain_block)
      @chain_block_val = chain_block_val
      @chain_block = chain_block
      @pids = {}
    end
    
    def chain_for_pid(pid)
      @pids[pid] ||= @chain_block.call(pid, @chain_block_val)
    end

    def << event
      pid = event.fields['pid']
      sink = chain_for_pid(pid)
      sink << event
    end



  end

end