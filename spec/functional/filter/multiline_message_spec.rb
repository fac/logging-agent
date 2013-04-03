require 'spec_helper'

describe LogAgent::Filter::MultilineMessage do
  let(:sink) { mock("MySink", :<< => nil) }
  
  it "should init with new( sink, options )" do
    filter = LogAgent::Filter::MultilineMessage.new sink, {:options => true}
    filter.sink.should == [sink]
    filter.options[:options].should be_true
  end
  
  describe "in :start => /regexp/, :end => /regexp/ mode" do
    let(:test_timestamp) { Time.now }
    let(:start_line) { LogAgent::Event.new :message => "START OF BLOCK", :type => "railz", :uuid => 'foo', :tags => ['tag1', 'tag2'], :timestamp => test_timestamp, :source_type => "source_type", :source_path => "source_path" }
    let(:end_line) { LogAgent::Event.new :message => "END OF BLOCK" }
    let(:line1) { LogAgent::Event.new :message => "extra line 1", :tags => ['another tag'] }
    let(:line2) { LogAgent::Event.new :message => "extra line 2" }
    
    let(:filter) { LogAgent::Filter::MultilineMessage.new sink, {:start => /^START/, :end => /^END/ } }
    
    it "should emit a single event for each event when not in a buffered block" do
      sink.should_receive(:<<).ordered.with(line1)
      sink.should_receive(:<<).ordered.with(line2)
      filter << line1
      filter << line2
    end
    
    describe "when the start token is seen" do
      before { filter << start_line }
      
      it "buffer all subsequent events" do
        sink.should_not_receive(:<<)
        filter << line1
        filter << line2
      end
    
      it "should emit a single event when the end regexp is matched" do
        sink.should_receive(:<<).exactly(1).times.with(an_instance_of(LogAgent::Event))
        filter << line1
        filter << line2
        filter << end_line
      end
      
      it "should emit a message with the same UUID, timestamp, source_*, tags and type as the start message" do
        sink.should_receive(:<<) { |event|
          event.uuid.should == 'foo'
          event.source_host.should == Socket.gethostname
          event.source_type.should == 'source_type'
          event.source_path.should == 'source_path'
          event.timestamp.should == test_timestamp
          event.type.should == 'railz'
          event.tags.should == ['tag1', 'tag2']
        }
        filter << line1
        filter << line2
        filter << end_line
      end
      it "should concatenate the lines of each event together, separated by newlines" do
        sink.should_receive(:<<) { |event|
          event.message.should == "START OF BLOCK\nextra line 1\nextra line 2\nEND OF BLOCK"
        }
        filter << line1
        filter << line2
        filter << end_line
      end
      it "should emit single events after the end of block" do
        sink.should_receive(:<<).ordered.with(an_instance_of(LogAgent::Event))
        sink.should_receive(:<<).ordered.with(line1)
        filter << line1
        filter << line2
        filter << end_line
        filter << line1        
      end
    end
    
  end
  
  
end
