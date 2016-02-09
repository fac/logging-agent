module LogAgent::Output
  class AMQP
    include LogAgent::LogHelper
    
    attr_reader :channel, :exchange
    def initialize channel, exchange
      @channel, @exchange = channel, exchange
    end
    
    def << event
      debug "Shipping event '#{event.uuid}'"
      @exchange.publish(event.to_payload, :routing_key => "#{event.type}.#{event.source_host}", :persistent => true) do
        yield if block_given?
      end
    end
  end
end
