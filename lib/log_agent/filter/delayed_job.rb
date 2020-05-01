module LogAgent::Filter
  class DelayedJob < Base

    include LogAgent::LogHelper

    def << event
      if event.message =~ /^Finished Job \[id=\d+\] after [\d.]+ms/
        event.primary = true
      end

      emit event
    end
  end
end
