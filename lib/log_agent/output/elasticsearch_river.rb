module LogAgent::Output
  class ElasticsearchRiver
    attr_reader :channel, :exchange, :routing_key

    def initialize( channel, exchange, routing_key, persistent_msgs = true )
      @channel, @routing_key, @persistent_msgs = channel, routing_key, persistent_msgs
      @exchange = if exchange.is_a? ::AMQP::Exchange
        exchange
      else
        @channel.direct(exchange)
      end
    end

    def << event
      action = {"index" => {
        "_timestamp"  => event.timestamp.iso8601(6),
        "_type"       => event.type || 'log',
        "_index"      => event.timestamp.strftime("logs-%Y-%m-%d"),
        "_id"         => event.uuid
      }}

      @exchange.publish( [JSON.dump(action),event.to_payload,""].join("\n"), :routing_key => @routing_key, :persistent => @persistent_msgs ) do
        yield if block_given?
      end
    end

  end
end
