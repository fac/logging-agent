module LogAgent
	module Filter
    class RailsLogTagParser < Base

      # Public: Read the list of configured tags
      #
      # Returns: A hash of the form:
      #  
      #   { "tag" => "field_name", ... }
      # 
      # where "tag" is the tag name in the log and "field_name" is the
      # name of the field in the log event. Even if the two are the same
      attr_reader :tags


      # Public: Creates an instance
      #
      # sink - the next Filter / Output in the chain
      # tags - Hash   = a hash of tags { "tag" => "field_name", ...}
      #      - Array  = an array of tags (the field name will be the same)
      #      - String = a single tag (the field name will be the same)
      #
      def initialize(sink, tags={})
        @tags = if tags.is_a?(Hash)
          tags
        elsif tags.is_a?(Array)
          Hash[tags.map { |v| [v,v] }]
        elsif tags.is_a?(String)
          {tags => tags}
        else
          raise ArgumentError, "#{tags.class} instance is not a valid tag"
        end
        super(sink)
      end

      # Public: Pass an event through this filter.
      def << event
        out_message = nil

        s = ::StringScanner.new(event.message)
        while s.check(/\[([^=\]]+)=?([^\]]+)?\]\s/)
          out_message ||= ""

          field_name = self.tags[s[1]]
          value = s[2]
          if field_name
            value ||= true
            event.fields[field_name] = value
          else
            out_message << s.matched
          end
          s.pos += s.matched_size
        end

        # If we don't match anything, don't bother updating the message
        if out_message
          event.message = [out_message,s.rest].compact.join
        end

        super(event)
      end
    end
  end
end
