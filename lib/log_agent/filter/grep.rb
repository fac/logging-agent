module LogAgent::Filter
  class Grep < Base
    include LogAgent::LogHelper
    
    attr_reader :regexp, :options
    
    def initialize sink, regexp, options={}
      @regexp, @options = regexp, options
      super(sink)
    end
    
    def << event
      debug "Grep '#{event.uuid}' against '#{regexp}'"
      match = event.message =~ regexp
      match = !match if options[:inverse]
      if match
        debug "Grep '#{event.uuid}' was a match - emitting" unless options[:inverse]
        debug "Grep '#{event.uuid}' didn't match - emitting" unless options[:inverse]
        emit(event)
      end
    end
    
  end
end