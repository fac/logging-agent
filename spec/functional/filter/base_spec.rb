require 'spec_helper'

describe LogAgent::Filter::Base do

  class FauxFilter < LogAgent::Filter::Base
  end

  let(:mock_sink) { mock("Sink", :<< => nil) }
  let(:filter) { FauxFilter.new(mock_sink)}

  describe "filter sink" do
    it "should have a #sink reader" do
      filter.sink.should == mock_sink
    end
    it "should call the filter's sink method when emit is called" do
      mock_sink.should_receive(:<<).with("an_event_here")
      filter.emit('an_event_here')
    end
  end

  it "should have a default implementation of << which simply emits the event" do
    mock_sink.should_receive(:<<).with("an_event")
    filter << 'an_event'
  end

  it "should allow multiple sink objects" do
    sink1 = mock("Sink1")
    sink2 = mock("Sink2")

    input = FauxFilter.new([sink1, sink2])
    sink1.should_receive(:<<).with("foo")
    sink2.should_receive(:<<).with("foo")    
    input.emit "foo"
  end
end