module LogAgent::Input

  class AMQP < Base

    include LogAgent::LogHelper

    attr_reader :channel, :exchange, :routing_key, :queue

    def initialize( sink, channel, exchange, routing_key, queue = nil )
      super sink

      @channel, @exchange, @routing_key = channel, exchange, routing_key

      if queue
        queue_ready(queue)
      else
        @channel.queue('', :auto_delete => true, :exclusive => true, &method(:queue_ready))
      end
    end

    # Callback from the AMQP server when the queue has been created,
    # or called directly from init if we get an external queue
    def queue_ready(queue)
      @queue = queue
      @queue.bind(@exchange, :routing_key => @routing_key) do |bind_ok|
        self.succeed
      end
      @queue.subscribe(:ack => true, &method(:message_received))
    end

    def message_received(header, payload)
      event = LogAgent::Event.from_payload(payload)
      EM::next_tick do
        emit(event) do
          header.ack
        end
      end
    rescue
      warn("Failed to decode JSON message: #{$!.message}")
      header.reject(:requeue => false)
    end
  end

end