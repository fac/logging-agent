require 'spec_helper'

describe LogAgent::Input::FileTail do
  include EventedSpec::EMSpec
  
  let(:sink) { mock("FileTailSink", :<< => nil) }

  let(:file_tail) { LogAgent::Input::FileTail.new sink, :path => '/tmp/mytest*.log', :tags => ['tag_a', 'tag_b'], :type => "rails" }
  let(:logfile1) { File.open("/tmp/mytest1.log", "a") }
  let(:logfile2) { File.open("/tmp/mytest2.log", "a") }

  em_before do
    file_tail
  end

  it "should configure the file path" do
    file_tail.path.should == '/tmp/mytest*.log'
    done
  end

  it "should succeed immediately" do
    file_tail.callback do
      done
    end
  end

  it "should call :<< with an Event object on the sink when a line is appended to a file" do
    sink.should_receive(:<<) { |event|
      event.should be_a(LogAgent::Event)
      done
    }
    EM.add_timer(0.1) { logfile1.puts "This is a logfile"; logfile1.flush }
  end

  it "should set the source_ flags on the event, appropriate to the source file" do
    sink.should_receive(:<<) { |event|
      event.source_host.should == Socket.gethostname
      event.source_type.should == 'file'
      event.source_path.should == "/tmp/mytest1.log"
      done
    }
    EM.add_timer(0.1) { logfile1.puts "This is a logfile"; logfile1.flush }
  end

  it "should handle more than one file" do
    sink.should_receive(:<<).ordered { |event|
      event.source_path.should == "/tmp/mytest1.log"
    }
    sink.should_receive(:<<).ordered { |event|
      event.source_path.should == "/tmp/mytest2.log"
      done
    }
    
    EM.add_timer(0.1) { logfile1.puts "This is a logfile"; logfile1.flush }
    EM.add_timer(0.2) { logfile2.puts "This is a logfile"; logfile2.flush }
  end
  
  it "should handle more than one glob" do
    sink2 = mock("AnotherSink")

    mylog1 = File.open("/tmp/mylog1.log", "a")
    mylog2 = File.open("/tmp/mylog2.log", "a")

    different_file_tail = LogAgent::Input::FileTail.new sink2, :path => ['/tmp/mylog1.*', '/tmp/mylog2.*']


    sink2.should_receive(:<<).ordered { |event|
      event.source_path.should == "/tmp/mylog1.log"
    }
    sink2.should_receive(:<<).ordered { |event|
      event.source_path.should == "/tmp/mylog2.log"
      done
    }
    
    EM.add_timer(0.1) { mylog1.puts "This is a mylog"; mylog1.flush }
    EM.add_timer(0.2) { mylog2.puts "This is a mylog"; mylog2.flush }
  end

  it "should assign the tags of the file to the Event" do
    sink.should_receive(:<<) { |event|
      event.tags.should include('tag_a')
      event.tags.should include('tag_b')
      done
    }
    EM.add_timer(0.1) { logfile1.puts "This is a logfile"; logfile1.flush }
  end

  it "should line-buffer the generated events" do
    sink.should_receive(:<<).ordered { |event|
      event.message.should == "This is the first line"
    }
    sink.should_receive(:<<).ordered { |event|
      event.message.should == "This is the second"
      done
    }
    EM.add_timer(0.1) { logfile1.write "This is the fi"; logfile1.flush }
    EM.add_timer(0.2) { logfile1.write "rst line\nThis is the second\n"; logfile1.flush }
  end

  describe "when type == :json" do
    before { file_tail.format = :json }
    
    it "should populate the fields and empty the message in the event if the FileTail is marked as :type => :json" do
      sink.should_receive(:<<) { |event|
        event.fields.should == {"cowsgo" => "moo", "dogsgo" => "woof"}
        event.message.should == ''
        done
      }
      EM.add_timer(0.2) { logfile1.puts %({"cowsgo":"moo","dogsgo":"woof"}); logfile1.flush }
    end

    it "should populate the message if the JSON parse fails" do
      LogAgent.logger.should_receive(:warn)
      sink.should_receive(:<<) { |event|
        event.message.should == '{"cowsgo":"moo","dFAIL!!!'
        done
      }
      EM.add_timer(0.2) { logfile1.puts %({"cowsgo":"moo","dFAIL!!!); logfile1.flush }
    end
  end

  describe "when type == :json_event" do
    em_before { file_tail.format = :json_event }
    
    it "should try and re-create the Event object from the JSON" do
      sink.should_receive(:<<) { |event|
        event.uuid.should == '1122334'
        done
      }
      EM.add_timer(0.1) { logfile1.puts LogAgent::Event.new(:uuid => "1122334").to_payload; logfile1.flush }
    end
    it "should populate the message if the creation fails" do
      LogAgent.logger.should_receive(:warn)
      sink.should_receive(:<<) { |event|
        event.message.should == "COWS GO BAAAAA"
        done
      }
      EM.add_timer(0.1) { logfile1.puts "COWS GO BAAAAA"; logfile1.flush }
    end
  end

  it "should set the message format on events" do
    file_tail.format = :json
    file_tail.message_format = "cowsgo %{cowsgo} and dogs go %{dogsgo}"
    sink.should_receive(:<<) { |event|
      event.message.should == 'cowsgo moo and dogs go woof'
      done
    }
    EM.add_timer(0.2) { logfile1.puts %({"cowsgo":"moo","dogsgo":"woof"}); logfile1.flush }
  end

  it "should set the type on events" do
    file_tail.message_format = "cowsgo %{cowsgo} and dogs go %{dogsgo}"
    sink.should_receive(:<<) { |event|
      event.type.should == 'rails'
      done
    }
    EM.add_timer(0.2) { logfile1.puts %({"cowsgo":"moo","dogsgo":"woof"}); logfile1.flush }
    
  end

  it "should send any data written to a file that has been seen before, since last seeing it"

# globbing / source_path in the 
# JSON type / JSON-event type / plain type
end

