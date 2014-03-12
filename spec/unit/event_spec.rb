require 'spec_helper'

describe LogAgent::Event, "behaviour" do
  let(:test_timestamp) { Time.now }
  let(:event) { LogAgent::Event.new({
    :type        => 'nginx-access',
    :fields      => {"foo" => "bar"},
    :timestamp   => test_timestamp,
    :tags        => ['car', 'basket'],
    :source_type => "file",
    :source_path => "/test/abc1.log"
  })}
  let(:empty_event) { LogAgent::Event.new}
  
  describe "captured_at" do
    it "should default to Time.now" do
      Timecop.freeze do
        LogAgent::Event.new.captured_at.should == Time.now
      end
    end

    it "should take the value specified on creation if present" do
      LogAgent::Event.new(:captured_at => test_timestamp).captured_at.should == test_timestamp
    end

    it "should persist the captured_at value through the payload" do
      LogAgent::Event.from_payload(LogAgent::Event.new(:captured_at => test_timestamp).to_payload).captured_at.should == test_timestamp
    end

  end

  describe "uuid" do
    it "should be generated on creation" do
      event.uuid.should_not be_nil
    end
  end
  
  describe "type" do
    it "should default to blank" do
      empty_event.type.should == ''
    end
    it "should be a string from the init hash" do
      event.type.should == 'nginx-access'
    end
    it "should be mutable" do
      event.type = 'nginx-access2'
      event.type.should == 'nginx-access2'
    end
  end
  
  describe "fields" do
    it "should have a #fields accessor that behaves like a hash" do
      event.fields['foo'].should == 'bar'
    end
    it "should be mutable" do
      event.fields['cowsay'] = 'moo'
      event.fields['cowsay'].should == 'moo'
    end
    it "should default the fields to an empty hash if omitted" do
      empty_event.fields.should == {}
    end
    it "should be possible to merge in fields" do
      event.fields.merge!({"dogsay" => "woof"})
      event.fields["dogsay"].should == "woof"
      event.fields["foo"].should == 'bar'
    end
  end
  
  describe "the timestamp" do
    it "should have a timestamp accessor" do
      event.timestamp.should == test_timestamp
    end
    it "should default the timestamp to the creation time, if it's omitted" do
      empty_event.timestamp.should be_a(Time)
    end
  end
  
  describe "the message" do
    it "should have a message accessor, returning a string" do
      event.message = "Foo bar baz"
      event.message
    end
    it "should default the message to a blank string if not provided" do
      empty_event.message.should == ''
    end
    
    describe "with a message format set" do
      it "should pull in the message format from the init options" do
        LogAgent::Event.new({ :message_format => "foo" }).message_format.should == "foo"
      end
      it "should have an immutable message" do
        event.message_format = "Foo Bar"
        lambda {
          event.message = "foo"
        }.should raise_error
      end
      it "should replace %{foo} with the field 'foo'" do
        event.fields = {"test1" => "Cowsay", "test2" => "MOO"}
        event.message_format = '%{test1} - %{test2}'
        event.message.should == "Cowsay - MOO"
      end
      it "should work even if the field value is non string" do
        event.fields = {"test1" => 12345, "test2" => "MOO"}
        event.message_format = '%{test1} - %{test2}'
        event.message.should == "12345 - MOO"
      end
      it "should replace %{@timestamp} with the timestamp in iso8601 format with decimal places" do
        event.timestamp = Time.now
        event.message_format = '%{@timestamp} FISH'
        event.message.should == "#{event.timestamp.iso8601(6)} FISH"
      end
      it "should replace %{@uuid} with the UUID" do
        event.message_format = 'UUID=%{@uuid}'
        event.message.should == "UUID=#{event.uuid}"
      end
      it "should replace %{@tags} with space separated tags" do
        event.tags = ['abc', '1234', 'def']
        event.message_format = '%{@tags}: STATIC'
        event.message.should == "abc 1234 def: STATIC"
      end
      it "should replace %{@tags:foo} with 'foo' separated strings" do
        event.tags = ['abc', '1234', 'def']
        event.message_format = '%{@tags:foo}: STATIC'
        event.message.should == "abcfoo1234foodef: STATIC"
      end
      it "should replace @source, @source_host, @source_path, @source_type" do
        event.message_format = '%{@source_type} ! %{@source_host} ! %{@source_path}'
        event.message.should == "file ! #{Socket.gethostname} ! /test/abc1.log"
      end
      
      it "should replace type with the type" do
        event.message_format = 'type=%{@type}'
        event.message.should == 'type=nginx-access'
      end
    end
  end
  
  describe "tags" do
    it "should default to an empty hash" do
      empty_event.tags.should == []
    end
    it "should be an array of strings" do
      event.tags.should == ['car', 'basket']
    end
    it "should be mutable" do
      event.tags << 'fish'
      event.tags.should include('fish')
    end
    it "should be able to concat tags" do
      event.tags.concat ["a", "b"]
      event.tags.should include('car')
      event.tags.should include('b')
    end
  end
  
  describe "source" do
    it "should default the source_host to the local hostname" do
      empty_event.source_host.should == Socket.gethostname
      event.source_host.should == Socket.gethostname
    end
    it "should default the source_path to an empty string" do
      empty_event.source_path.should == ''
      event.source_path.should == '/test/abc1.log'
    end
    it "should have a source type" do
      empty_event.source_type.should == ''
      event.source_type.should == 'file'
    end
    it "should be immutable" do
      lambda { event.source_type = 'fish' }.should raise_error
      lambda { event.source_path = 'fish' }.should raise_error
      lambda { event.source_host = 'fish' }.should raise_error
    end
  end

  describe "Event.from_payload" do
    let(:loaded) { LogAgent::Event.from_payload(event.to_payload) }
    
    it "should return an Event object" do
      loaded.should be_a(LogAgent::Event)
    end

    it "should load the object even if @captured_at isn't present" do
      Timecop.freeze do
        payload = JSON.dump(JSON.load(event.to_payload.tap { |hash| hash.delete("@captured_at") }))
        LogAgent::Event.from_payload(payload).captured_at.should == Time.now
      end
    end
    
    it "should load the object even if @timestamp isn't present" do
      Timecop.freeze do
        payload = JSON.dump(JSON.load(event.to_payload.tap { |hash| hash.delete("@timestamp") }))
        LogAgent::Event.from_payload(payload).timestamp.should == Time.now
      end
    end

    it "should load the @timestamp field" do
      loaded.timestamp.iso8601(6).should == event.timestamp.iso8601(6)
    end

    it "should load the @source_host field" do
      event
      Socket.stub!(:gethostname => "a.n.other.host")
      loaded.source_host.should == event.source_host
    end
    
    it "should load the @source_type field" do
      loaded.source_type.should == event.source_type
    end
    it "should load the @source_path field" do
      loaded.source_path.should == event.source_path
    end
    it "should load the @type field" do
      loaded.type.should == event.type
    end
    it "should load the @tags array" do
      loaded.tags.should == event.tags
    end
    it "should load the @message out" do
      loaded.message.should == event.message
    end
    it "should only load a static message, even when a message format was used" do
      event.message_format = 'FOO BAR %{foo}'
      loaded.message.should == "FOO BAR bar"
      loaded.message_format.should be_nil
    end
    it "should load @fields hash" do
      loaded.fields.should == event.fields
    end
    it "should load the @uuid field" do
      loaded.uuid.should == event.uuid
    end
  end

  describe "to_payload" do
    let(:json_out) { JSON.load(event.to_payload) }
    
    it "should write the @timestamp as an iso8601(6) field" do
      json_out['@timestamp'].should == event.timestamp.iso8601(6)
    end
    it "should write the @source_host field" do
      json_out['@source_host'].should == event.source_host
    end
    it "should write the @source_type field" do
      json_out['@source_type'].should == event.source_type
    end
    it "should write the @source_path field" do
      json_out['@source_path'].should == event.source_path
    end
    it "should write the @type field" do
      json_out['@type'].should == event.type
    end
    it "should write the @tags array" do
      json_out['@tags'].should be_a(Array)
      json_out['@tags'].should == event.tags
    end
    it "should write the @message out" do
      json_out['@message'].should == event.message
    end
    it "should write the formatted message, if that's configured" do
      event.message_format = 'FOO BAR %{foo}'
      JSON.load(event.to_payload)['@message'].should == 'FOO BAR bar'
    end
    it "should not write out the @message_format" do
      json_out['@message_format'].should be_nil
    end
    it "should write out @fields hash" do
      json_out['@fields'].should be_a(Hash)
      json_out['@fields'].should == event.fields
    end
    it "should write out the @uuid" do
      json_out['@uuid'].should == event.uuid
    end
  end
  
end
