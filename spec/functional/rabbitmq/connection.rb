require 'spec_helper'

describe "LogAgent connection to rabbitmq" do

  it "should connect without error using Connection.next_channel_id to pick an ID" do

    EventMachine.run do
      AMQP.connect do |connection|
        channel = AMQP::Channel.new(connection, connection.next_channel_id)
        connection.should be_open
        connection.close { EventMachine.stop }
      end
    end

  end
end
