require 'spec_helper'

describe LogAgent::Input::Base do

  class FauxInput < LogAgent::Input::Base
  end

  let(:mock_sink) { mock("Sink", :<< => nil) }
  let(:input) { FauxInput.new( mock_sink ) }

  it "should take a sink as the first parameter" do
    FauxInput.new( mock_sink )
  end

  it "should have a sink accessor" do
    input.sink.should == mock_sink
  end
  
  it "should call the sink's << method when an event is emitted" do
    mock_sink.should_receive(:<<).with('foobar')
    input.emit('foobar')
  end

  describe "deferrable" do

    it "should implement a deferrable" do
      LogAgent::Input::Base.included_modules.should include(EventMachine::Deferrable)
    end
  end

  it "should allow multiple sink objects" do
    sink1 = mock("Sink1")
    sink2 = mock("Sink2")

    input = FauxInput.new([sink1, sink2])
    sink1.should_receive(:<<).with("foo")
    sink2.should_receive(:<<).with("foo")    
    input.emit "foo"
  end
end
