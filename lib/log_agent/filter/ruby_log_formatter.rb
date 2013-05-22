module LogAgent::Filter
  class RubyLogFormatter < Base

    include LogAgent::LogHelper

    def << event
      if event.message =~/^[A-Z], \[(.*) #[0-9]+\]  [A-Z]+ -- : /
        timestamp = Time.parse($1) rescue nil
        event.timestamp = timestamp if timestamp
      end

      event.message.sub!(/^[A-Z], \[.* #[0-9]+\]  [A-Z]+ -- : /, '')
      emit event
    end
  end
end
