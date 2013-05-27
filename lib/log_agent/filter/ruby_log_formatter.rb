module LogAgent::Filter
  class RubyLogFormatter < Base

    include LogAgent::LogHelper

    def << event
      if event.message =~/^[A-Z],\s*\[([0-9\-\:T\.]+)\s*#([0-9]+)\]\s*[A-Z]+ -- : (.*)$/
        event.timestamp = begin
          event.captured_at = Time.parse("#{$1} UTC")
        rescue
          nil
        end

        event.fields['pid'] = $2
        event.message = $3
      end
      emit event
    end
  end
end
