module LogAgent::Input
  class Base
    include EventMachine::Deferrable

    attr_reader :sink

    def initialize( sink )
      @sink = [sink].flatten
    end

    def emit event, &block
      count = @sink.count if block_given?
      sink.each do |s|
        s.<<(event) do

          if block_given?
            count -= 1
            yield if count == 0
          end
        end
      end
    end
  end
end