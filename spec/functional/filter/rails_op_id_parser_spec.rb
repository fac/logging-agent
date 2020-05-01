require 'spec_helper'

describe LogAgent::Filter::RailsOpIdParser do
  let(:sink)   { mock("Sink",  :<< => nil) }
  let(:filter) { LogAgent::Filter::RailsOpIdParser.new(sink)}

  it "should pass on any log messages that don't contain a log tag" do
    sink.should_receive(:<<) do |event|
      event.message.should == "a message"
    end
    filter << LogAgent::Event.new(:message => "a message")
  end

  it "should pass on any unrecognised tags" do
    sink.should_receive(:<<) { |event| event.message.should == "[random_tag=stuff] Something happened!" }

    filter << LogAgent::Event.new(:message => "[random_tag=stuff] Something happened!")
  end

  describe "when a recognised tag is found" do
    before do
      sink.should_receive(:<<).with { |event| @event = event }
    end

    it "should remove the tag text from the message" do
      filter << LogAgent::Event.new(:message => "[op=1234] Some text")
      @event.message.should == "Some text"
    end

    it "should not ignore any tags only prefixed by other tags" do
      filter << LogAgent::Event.new(:message => "[other_tag=foo] [op=abc] A message")
      @event.message.should == "[other_tag=foo] A message"
    end

    it "should assign the tag value to the configured field" do
      filter << LogAgent::Event.new(:message => "[other_tag=foo] [op=1234] [foo=value] A message")
      @event.op_id.should == "1234"
    end

    it "should dump the op id field if it is set" do
      filter << LogAgent::Event.new(:message => "[other_tag=foo] [op=1234] [foo=value] A message")
      JSON.load(@event.to_payload)["@op_id"].should == "1234"
    end

    it "should not dump the op id field if it is not set" do
      filter << LogAgent::Event.new(:message => "[other_tag=foo] [foo=value] A message")
      JSON.load(@event.to_payload).key?("@op_id").should == false
    end
  end
end

