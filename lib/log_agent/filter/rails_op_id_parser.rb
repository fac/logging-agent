require 'strscan'
module LogAgent
  module Filter
    class RailsOpIdParser < Base

      # Public: Creates an instance
      #
      # sink - the next Filter / Output in the chain
      def initialize(sink)
        super(sink)
      end

      # Public: Pass an event through this filter.
      def << event
        out_message = nil

        if (match_data = event.message.match(/(.*)\[op=([^\]]+)\]\s(.*)/))
          event.op_id = match_data[2]
          event.message = "#{match_data[1]}#{match_data[3]}"
        end

        super(event)
      end
    end
  end
end
