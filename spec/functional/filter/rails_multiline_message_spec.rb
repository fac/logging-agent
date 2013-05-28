require 'spec_helper'

describe LogAgent::Filter::RailsMultilineMessage do

  class EventSink
    attr_reader :events
    def initialize
      @events = []
    end
    def << event
      @events << event
    end
  end

  let(:sink) { EventSink.new }
  let(:filter) { LogAgent::Filter::RailsMultilineMessage.new(sink, 'req', nil) }


  describe "log-entries with [req=foobar] prefix" do

    it "should buffer until a different request id is received" do
      filter << LogAgent::Event.new(:message => '[req=1234] First line')
      filter << LogAgent::Event.new(:message => '[req=1234] Second line')
      sink.events.size.should == 0
    end

    describe "with some different requests received" do
      before do
        filter << LogAgent::Event.new(:message => '[req=1234] First line')
        filter << LogAgent::Event.new(:message => '[req=1234] Second line')

        filter << LogAgent::Event.new(:message => '[req=2345] Another First line')
        filter << LogAgent::Event.new(:message => '[req=2345] Another Second line')

        # Fire in another event to get the old one to stop buffering
        filter << LogAgent::Event.new(:message => '[req=3456] Second line')
      end
      it "should concatenate them into single events" do
        sink.events.size.should == 2
        sink.events.first.message.should == "First line\nSecond line"
        sink.events.last.message.should == "Another First line\nAnother Second line"
      end

      it "should write the request id into the fields" do
        sink.events.first.fields['request_id'].should == '1234'
        sink.events.last.fields['request_id'].should == '2345'
      end
    end

    it "should return immediately if the completion regexp matches" do
      filter << LogAgent::Event.new(:message => '[req=1234] First line')
      filter << LogAgent::Event.new(:message => '[req=1234] Completed first request')
      sink.events.size.should == 1
      sink.events.first.message.should == "First line\nCompleted first request"
      sink.events.first.fields['request_id'].should == "1234"
    end

    it "should still buffer subsequent messages OK after a completion match" do
      filter << LogAgent::Event.new(:message => '[req=1234] First line')
      filter << LogAgent::Event.new(:message => '[req=1234] Completed first request')
      filter << LogAgent::Event.new(:message => '[req=2345] Second request line')
      filter << LogAgent::Event.new(:message => '[req=2345] Completed second request')
      sink.events[1].message.should == "Second request line\nCompleted second request"
    end

    it "should return immediately for a single line if it matches the completion match" do
      filter << LogAgent::Event.new(:message => '[req=1234] Completed short line')
      sink.events.size.should == 1
    end

    describe "lines without a prefix (such as an exception)" do
      it "should wrap them into the current requestion" do
        filter << LogAgent::Event.new(:message => '[req=1234] First line')
        filter << LogAgent::Event.new(:message => 'OH MY GOD')
        filter << LogAgent::Event.new(:message => 'IT ALL BROKE')

        filter << LogAgent::Event.new(:message => '[req=2345] Another First line')
        filter << LogAgent::Event.new(:message => '[req=2345] Completed Second line')

        sink.events.size.should == 2
        sink.events.first.message.should == "First line\nOH MY GOD\nIT ALL BROKE"
      end
    end
  end

  describe "as soon as the message buffer length exceeds max-length" do
    let(:filter) { LogAgent::Filter::RailsMultilineMessage.new(sink, 'req', nil, 10) }

    it "should emit the buffer straight away" do
      filter << LogAgent::Event.new(:message => '[req=1234] 12345')
      filter << LogAgent::Event.new(:message => '[req=1234] 6789012')

      sink.events.size.should == 1
      sink.events.first.message.should == "12345\n6789012"
    end

    it "should still buffer subsequent messages" do
      filter << LogAgent::Event.new(:message => '[req=1234] 12345')
      filter << LogAgent::Event.new(:message => '[req=1234] 6789012')
      filter << LogAgent::Event.new(:message => '[req=2345] 123')
      filter << LogAgent::Event.new(:message => '[req=2345] 456')
      filter << LogAgent::Event.new(:message => '[req=3456] Another')
      sink.events.size.should == 2
      sink.events[0].message.should == "12345\n6789012"
      sink.events[1].message.should == "123\n456"
    end
  end

end

