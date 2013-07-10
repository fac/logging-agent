require 'spec_helper'

describe LogAgent::Filter::RailsLogTagParser do
  let(:sink)   { mock("Sink",  :<< => nil) }
  let(:filter) { LogAgent::Filter::RailsLogTagParser.new(sink, {"tag" => "field_name", "foo" => "bar"})}

  it "should have a tags reader" do
    filter.tags.should == {"tag" => "field_name", "foo" => "bar"}
  end

  it "should allow a single tag to be configured" do
    LogAgent::Filter::RailsLogTagParser.new(sink, "the_tag").tags.should == { "the_tag" => "the_tag"}
  end
  it "should allow an array of tags to be configured" do
    LogAgent::Filter::RailsLogTagParser.new(sink, ["tag1", "tag2"]).tags.should == {"tag1" => "tag1", "tag2" => "tag2"}
  end

  it "should raise an exception if the tag value isn't a Hash, Array or String" do
    lambda { 
      LogAgent::Filter::RailsLogTagParser.new(sink, Time.now)
    }.should raise_error(ArgumentError, 'Time instance is not a valid tag')
  end
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

    it "should ignore any tags not at the start of the line" do
      filter << LogAgent::Event.new(:message => "Some text before [tag=stuff] A message")
      @event.message.should == "Some text before [tag=stuff] A message"
    end

    it "should remove the tag text from the message" do
      filter << LogAgent::Event.new(:message => "[tag=value] Some text")
      @event.message.should == "Some text"
    end

    it "should set keys without a value to true" do
      filter << LogAgent::Event.new(:message => "[THING] [tag=stuff] [foo] A message")
      @event.message.should == "[THING] A message"
      @event.fields['bar'].should be_true
    end

    it "should not ignore any tags only prefixed by other tags" do
      filter << LogAgent::Event.new(:message => "[other_tag=foo] [tag=stuff] A message")
      @event.message.should == "[other_tag=foo] A message"
    end

    it  "should assign the tag value to the configured field" do
      filter << LogAgent::Event.new(:message => "[other_tag=foo] [tag=stuff] [foo=value] A message")
      @event.fields['field_name'].should == "stuff"
      @event.fields['bar'].should == "value"
    end
  end
end

