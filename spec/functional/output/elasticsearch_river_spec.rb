require 'spec_helper'

describe LogAgent::Output::ElasticsearchRiver, "creation" do
  include EventedSpec::AMQPSpec

  let(:channel) { AMQP::Channel.new }
  let(:output) { LogAgent::Output::ElasticsearchRiver.new channel, 'es-dev', 'key' }

  it "should take channel, exchange and routing key parameters and define a direct exchange" do
    output.channel.should == channel
    output.exchange.should be_a(AMQP::Exchange)
    output.exchange.type.should == :direct
    output.routing_key.should == 'key'
    done
  end

  it "should use an exchange object if passed in" do
    exchange = channel.fanout('test-exchange')
    output = LogAgent::Output::ElasticsearchRiver.new channel, exchange, 'foobar'
    exchange.should_receive(:publish) do |message, args|
      args[:routing_key].should == "foobar"
      done
    end
    output << LogAgent::Event.new
  end

  describe "when an event is received" do
    let(:the_time) { Time.at(1334319450.12345) }
    let(:queue) { channel.queue('testqueue', :auto_delete => true, :exclusive => true).bind('es-dev', :routing_key => 'key') }
    let(:event) { LogAgent::Event.new(:timestamp => the_time, :uuid => 'the_uuid', :type => 'the_type', :message => "foobar") }
    amqp_before do
      # define the output
      output

      # on the next reactor tick, i.e. after the spec, post the event
      EM::next_tick do
        output << event
      end
    end

    it "should publish a message to the exchange, with the specified routing key, for each event consumed" do
      queue.subscribe do |header, payload|
        header.routing_key.should == 'key'
        done
      end
    end

    it "should prepend an indexing line to the Event payload" do
      queue.subscribe do |header, payload|
        header, payload = payload.split("\n")
        event = LogAgent::Event.from_payload(payload)
        event.timestamp.iso8601(6).should == the_time.iso8601(6)
        event.message.should == 'foobar'
        done
      end
    end

    it "should have use the event's iso8601 timestamp, type and uuid in the indexing action" do
      queue.subscribe do |header, payload|
        header, payload, _ = payload.split("\n")
        header = JSON.load(header)
        header["index"]["_timestamp"].should == the_time.iso8601(6)
        header["index"]["_type"].should == 'the_type'
        header["index"]['_id'].should == 'the_uuid'
        done
      end

    end
    it "should specify an index name based on the timestamp date" do
      queue.subscribe do |header, payload|
        header, payload, _ = payload.split("\n")
        header = JSON.load(header)
        header["index"]["_index"].should == 'logs-2012-04-13'
        done
      end
    end
    it "should default the type to log" do
      event.type = nil
      queue.subscribe do |header, payload|
        header, payload, _ = payload.split("\n")
        header = JSON.load(header)
        header["index"]["_type"].should == 'log'
        done
      end
    end
    it "should append a blank line" do
      event.type = nil
      queue.subscribe do |header, payload|
        payload[-1].should == "\n"
        done
      end

    end
  end
end