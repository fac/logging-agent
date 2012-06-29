require 'spec_helper'

describe LogAgent::Filter::Grep do
  let(:sink) { mock("MySinkObject", :<< => nil) }
  
  it "should be created with new <sink>, /regexp/, opts={}" do
    filter = LogAgent::Filter::Grep.new sink, /regexp/, :options => true
    filter.sink.should == sink
    filter.regexp.should == /regexp/
    filter.options[:options].should be_true
  end
  
  describe "in default mode" do
    let(:filter) { LogAgent::Filter::Grep.new sink, /\d{1,3}.\d{1,3}.\d{1,3}.\d{1,3}/ }
    it "should emit events where the message matches the regular expression" do
      event = LogAgent::Event.new :message => "This is the IP: 1.23.45.6"
      sink.should_receive(:<<).with(event)
      filter << event
    end
    it "should not emit events where the message doesn't match the regular expression" do
      event = LogAgent::Event.new :message => "No IP address here, today..."
      sink.should_not_receive(:<<)
      filter << event
    end
  end
  
  describe "in inverse mode" do
    let(:filter) { LogAgent::Filter::Grep.new sink, /\d{1,3}.\d{1,3}.\d{1,3}.\d{1,3}/, :inverse => true }
    it "should not emit events where the message matches the regular expression" do
      event = LogAgent::Event.new :message => "This is the IP: 1.23.45.6"
      sink.should_not_receive(:<<)
      filter << event
    end
    it "should emit events where the message doesn't match the regular expression" do
      event = LogAgent::Event.new :message => "No IP address here, today..."
      sink.should_receive(:<<).with(event)
      filter << event
    end
  end
  
  
end
