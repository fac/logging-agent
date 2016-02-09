module LogAgent::Output
  class AMQP
    include LogAgent::LogHelper

    attr_reader :channel, :exchange, :persistent_msgs
    # Initialise AMQP output module
    #
    # * channel - Bunny channle
    # * exchange - Bunny exchange
    # * persistent_msgs - Should messages survive a broker restart
    #   persistent_msgs defaults to true.
    def initialize(channel, exchange, persistent_msgs = true)
      @channel, @exchange, @persistent_msgs = channel, exchange, persistent_msgs
    end

    def << event
      debug "Shipping event '#{event.uuid}'"
      @exchange.publish(
        event.to_payload,
        :routing_key => "#{event.type}.#{event.source_host}",
        :persistent  => persistent_msgs
      ) do
        yield if block_given?
      end
    end
  end
end
