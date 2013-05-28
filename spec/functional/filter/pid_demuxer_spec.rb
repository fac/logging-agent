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
    attr_reader :tag
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
        EventFilter.new(sink, "pid-object-#{pid}") unless pid == 9999
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

    it "should drop events when a nil value is returned from the block" do
      @filter << LogAgent::Event.new(:message => "pid1-message", :fields => {'pid' => 9999})
      @filter << LogAgent::Event.new(:message => "pid1-message", :fields => {'pid' => 9999})
      sink.events.size.should == 4
    end
  end

  it "should presume events without a PID have the same pid as the previous message" do
    filter << LogAgent::Event.new(:message => "pid1-message", :fields => {'pid' => 9999})
    filter << LogAgent::Event.new(:message => "pid1-message")
    sink.events.size.should == 2
    sink.events.first.tags.should include('pid-object-9999')
    sink.events.last.tags.should include('pid-object-9999')
  end

  describe "pid cleanup" do

    it "should default the pid-timeout to 60 seconds" do
      filter.pid_timeout.should == 60
    end

    describe "with a custom timeout value" do
      let(:filter) { LogAgent::Filter::PidDemuxer.new(sink, :timeout => 0.1) { |pid, sink| EventFilter.new(sink, "pid-timeout-#{pid}") } }

      it "should allow the timeout to be tweaked" do
        filter.pid_timeout.should == 0.1
      end

      it "should allow the PID sink to be cleaned up when it has not been used for pid-timeout second" do
        filter << LogAgent::Event.new(:message => "pid1-message", :fields => {'pid' => 1234})
        sleep 0.2
        filter << LogAgent::Event.new(:message => "pid1-message", :fields => {'pid' => 2345})
        GC.start
        ObjectSpace.each_object(EventFilter).find { |obj| obj.tag == 'pid-timeout-1234' }.should be_nil
      end

    end


  end


end
