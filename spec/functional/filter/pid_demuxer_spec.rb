require 'spec_helper'

describe LogAgent::Filter::PidDemuxer do

  class EventSink
    attr_reader :events
    def initialize
      @events = []
    end
    def << event
      @events << event
    end
  end
  class EventFilter < LogAgent::Filter::Base
    def initialize(sink, tag)
      @tag = tag
      super(sink)
    end
    def << event
      event.tags << @tag
      emit event
    end
  end

  let(:sink) { EventSink.new }
  let(:filter) do
    LogAgent::Filter::PidDemuxer.new(sink) { |pid, sink| EventFilter.new(sink, "pid-object-#{pid}") }
  end

  describe "construction" do

    before do
      @block_calls = []
      @filter = LogAgent::Filter::PidDemuxer.new(sink) do |pid, sink|
        @block_calls << [pid, sink]
        EventFilter.new(sink, "pid-object-#{pid}")
      end

      @filter << LogAgent::Event.new(:message => "pid1-message", :fields => {'pid' => 1234})
      @filter << LogAgent::Event.new(:message => "pid1-message", :fields => {'pid' => 2345})
      @filter << LogAgent::Event.new(:message => "pid1-message", :fields => {'pid' => 2345})
      @filter << LogAgent::Event.new(:message => "pid1-message", :fields => {'pid' => 3456})
    end

    it "should yield for each new PID seen" do
      @block_calls.size.should == 3
    end

    it "should pass the init argument through to the block second argument" do
      @block_calls.map { |a| a[1] }.should == [sink, sink, sink]
    end

    it "should pass the pid as the first block argument" do
      @block_calls.map { |a| a[0] }.should == [1234, 2345, 3456]
    end

    it "should use the returned object as the chain" do
      sink.events.size.should == 4
      sink.events.first.tags.should include('pid-object-1234')
      sink.events.last.tags.should include('pid-object-3456')
    end
  end


end
