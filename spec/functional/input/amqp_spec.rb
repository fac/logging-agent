require 'spec_helper'

describe LogAgent::Input::AMQP, "creation" do
  include EventedSpec::AMQPSpec

  default_timeout 1.0

  let(:channel) { AMQP::Channel.new }
  let(:exchange) { channel.fanout('dev-logs') }

  let(:my_sink ) { mock("Sink", :<< => nil ) }

  amqp_before do
    # make sure the exchange exists before our input tries to bind!
    exchange
  end

  describe "without a queue specified" do
    let(:input) { LogAgent::Input::AMQP.new(my_sink, channel, 'dev-logs', '#') }

    it "should specify the channel, exchange name and routing key filter" do
      input.channel.should == channel
      input.exchange.should == 'dev-logs'
      input.routing_key.should == '#'
      done
    end

    it "should callback after init'ing" do
      input.callback do
        done
      end
    end

    it "should emit an Event object for any message received to the exchange" do
      my_sink.should_receive(:<<) do |event|
        event.should be_a(LogAgent::Event)
        done
      end

      input.callback do
        exchange.publish LogAgent::Event.new.to_payload, :routing_key => 'logs'
      end
    end

    it "should report an unparseable message and continue" do
      my_sink.should_not_receive(:<<)
      LogAgent.logger.should_receive(:warn) { |message|
        message.should =~ /unexpected token at 'gibberish'/
        done
      }

      input.callback do
        exchange.publish "gibberish", :routing_key => 'logs'
      end
    end
  end

  describe "when a queue is specified" do
    let(:queue) { channel.queue('dev-queue', :durable => true, :arguments => {'x-expiry' => 1000} ) }
    let(:input) { LogAgent::Input::AMQP.new(my_sink, channel, 'dev-logs', '#', queue) }

    amqp_before do
      queue.purge
    end

    it "should use the supplied queue" do
      input.queue.should == queue
      done
    end

    it "should still bind the queue to the exchange" do
      input.callback do
        input.queue.bindings.first[:exchange].should == 'dev-logs'
        input.queue.bindings.first[:routing_key].should == '#'
        done
      end
    end
    it "should succeed immediately" do
      input.callback do
        done
      end
    end

  end

end

