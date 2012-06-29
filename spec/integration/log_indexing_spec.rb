require 'spec_helper'

# As an engineer
# I want to have real-time log-data arriving at our MQ server
#   indexed as soom as possible into ElasticSearch
# So we need an agent to queue up log-messages, re-format them
#   and deliver them into the ES river.

describe "Log Indexing with a durable shared queue" do
  include EventedSpec::AMQPSpec

  let(:channel) { AMQP::Channel.new }

  let(:output_exchange) { channel.fanout('dev-elasticsearch', :durable => true) }

  let(:shared_queue) { channel.queue('dev-queue2', :arguments => {'x-expiry' => "500" } ) }

  let(:input_exchange) { channel.fanout('logs') }

  amqp_before do
    channel.on_error do |ch, channel_close|
      raise channel_close.reply_text
    end

    input_exchange
    output_exchange

    # Hook up to an ES-river indexer
    @river = LogAgent::Output::ElasticsearchRiver.new(channel, output_exchange, 'elasticsearch')

    # Get an AMQP source listening to the logs exchange, with no key filter    
    @source = LogAgent::Input::AMQP.new(@river, channel, 'logs', '#', shared_queue)
  end

  it "should emit a river message when an AMQP is received to the input exchange" do
    channel.queue('testqueue', :auto_delete => true, :exclusive => true ).bind(output_exchange).subscribe do |header,message|
      header, event = message.split("\n")
      JSON.load(header)['index'].should be_a(Hash)
      LogAgent::Event.from_payload(event).should be_a(LogAgent::Event)
      done
    end

    @source.callback do
      input_exchange.publish(LogAgent::Event.new.to_payload)
    end
  end
end
