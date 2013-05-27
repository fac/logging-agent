module LogAgent::Filter
  class RubyLogFormatter < Base

    include LogAgent::LogHelper

    def << event
      if event.message =~/^[A-Z], \[(.*) #([0-9]+)\]  [A-Z]+ -- : (.*)$/
        event.timestamp = begin
          Time.parse("#{$1} UTC")
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
