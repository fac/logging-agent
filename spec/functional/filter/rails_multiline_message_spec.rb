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


  describe "for messages with a pid and request id" do

    describe "simple message" do
      before do
        filter << LogAgent::Event.new(:message => "[req=12345] I'm the first line", :fields => {'pid' => 9999})
        filter << LogAgent::Event.new(:message => "[req=12345] I'm the second line", :fields => {'pid' => 9999})

        # The event will be emitted when the next event from the same pid is received
        filter << LogAgent::Event.new(:message => "[req=23456] I'm the next request", :fields => {'pid' => 9999})
      end

      it "should concatenate events with the same request id" do
        sink.events.size.should == 1
      end

      it "should reduce the messages and trim the request id" do
        sink.events.first.message.should == "I'm the first line\nI'm the second line"
      end

      it "should set the request id on the outgoing message" do
        sink.events.first.fields['rails_request_id'].should == "12345"
      end
    end

    describe "demux between pids" do
      before do
        filter << LogAgent::Event.new(:message => "[req=12345] First pid, first line", :fields => {'pid' => 9999})
        filter << LogAgent::Event.new(:message => "[req=34567] Second pid, first line", :fields => {'pid' => 8888})
        filter << LogAgent::Event.new(:message => "[req=12345] First pid, second line", :fields => {'pid' => 9999})
        filter << LogAgent::Event.new(:message => "[req=34567] Second pid, second line", :fields => {'pid' => 8888})

        # The event will be emitted when the next event from the same pid is received
        filter << LogAgent::Event.new(:message => "[req=23456] I'm the next request", :fields => {'pid' => 9999})
        filter << LogAgent::Event.new(:message => "[req=45678] I'm the next request", :fields => {'pid' => 8888})
      end

      it "should demux the pids" do
        sink.events.size.should == 2
      end

      it "should reduce both messages correctly" do
        sink.events.first.tap do |first_pid|
          first_pid.message.should == "First pid, first line\nFirst pid, second line"
          first_pid.fields['pid'].should == 9999
          first_pid.fields['rails_request_id'].should == '12345'
        end
        sink.events.last.tap do |second_pid|
          second_pid.message.should == "Second pid, first line\nSecond pid, second line"
          second_pid.fields['pid'].should == 8888
          second_pid.fields['rails_request_id'].should == "34567"
        end
      end

    end

    it "should immediately dispatch an event when it matches /^Completed" do
      filter << LogAgent::Event.new(:message => "[req=12345] First pid, first line", :fields => {'pid' => 9999})
      filter << LogAgent::Event.new(:message => "[req=34567] Second pid, first line", :fields => {'pid' => 8888})
      filter << LogAgent::Event.new(:message => "[req=12345] Completed first request", :fields => {'pid' => 9999})
      filter << LogAgent::Event.new(:message => "[req=34567] Completed second request", :fields => {'pid' => 8888})

      sink.events.size.should == 2
      sink.events.last.message.should == "Second pid, first line\nCompleted second request"
    end

    it "shouldn't blow up if there is a one-line Completed request" do
      filter << LogAgent::Event.new(:message => "[req=34567] Completed second request", :fields => {'pid' => 8888})      
      sink.events.first.message.should == "Completed second request"
    end

    describe "max-size parameter" do

      let(:filter) { LogAgent::Filter::RailsMultilineMessage.new(sink, 'req', nil, 10) }

      it "should emit the combined event when the combined message exceeds the max-size" do
        filter << LogAgent::Event.new(:message => "[req=12345] 123456", :fields => {'pid' => 9999})
        filter << LogAgent::Event.new(:message => "[req=12345] 789012", :fields => {'pid' => 9999})
        filter << LogAgent::Event.new(:message => "[req=12345] 345678", :fields => {'pid' => 9999})

        sink.events.size.should == 1
        sink.events.first.message.should == "123456\n789012"
      end

    end

    describe "max-time parameter" do
      include EventedSpec::EMSpec

      let(:filter) { LogAgent::Filter::RailsMultilineMessage.new(sink, 'req', 0.1) }

      it "should emit the combined event afer max-time has elapsed" do
        filter << LogAgent::Event.new(:message => "[req=12345] First pid, first line", :fields => {'pid' => 9999})

        EM.add_timer(0.2) do
          sink.events.size.should == 1
          sink.events.first.message.should == "First pid, first line"
          done
        end
      end
      it "should reset the max-time counter after each new event is received" do
        filter << LogAgent::Event.new(:message => "[req=12345] First pid, first line", :fields => {'pid' => 9999})
        EM.add_timer(0.05) do
          filter << LogAgent::Event.new(:message => "[req=12345] First pid, second line", :fields => {'pid' => 9999})
        end
        EM.add_timer(0.14) do
          filter << LogAgent::Event.new(:message => "[req=12345] First pid, third line", :fields => {'pid' => 9999})
        end
        EM.add_timer(0.30) do
          sink.events.size.should == 1
          sink.events.first.message.should == "First pid, first line\nFirst pid, second line\nFirst pid, third line"
          done
        end
      end

    end

  end


end

