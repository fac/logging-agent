require 'spec_helper'

describe LogAgent::Output::AMQP do
  include EventedSpec::AMQPSpec
  
  let(:channel) { AMQP::Channel.new}
  let(:exchange) { channel.fanout('logging-exchange', :durable => false) }
  let(:shipper) { LogAgent::Output::AMQP.new channel, exchange }
  let(:test_queue) { channel.queue('test-queue-2', :auto_delete => true, :exclusive => true) }

  amqp_before do
    channel.on_error do |ch, channel_close|
      p channel_close
    end
    test_queue.purge
    test_queue.bind(exchange)
  end
  
  it "should take a channel and exchange name as arguments" do
    shipper.channel.should == channel
    shipper.exchange.should == exchange
    done
  end
  
  it "should generate a JSON AMQP message for each event hash that is received" do
    test_queue.subscribe do |header, payload|
      LogAgent::Event.from_payload( payload ).type.should == "nginx"
      done
    end
    
    shipper << LogAgent::Event.new({ :type => 'nginx'})
  end
  
  it "should set a routing key based on event_type.source_host" do
    test_queue.subscribe do |header, payload|
      header.routing_key.should == "nginx.#{Socket.gethostname}"
      done
    end
    
    shipper << LogAgent::Event.new({ :type => 'nginx'})
  end
end