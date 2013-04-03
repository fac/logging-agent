module LogAgent::Output
  class Null
    include LogAgent::LogHelper
    
    def initialize
    end
    
    def << event
      debug "Shipping event '#{event.uuid}'"
      info event.inspect
    end
  end
end
