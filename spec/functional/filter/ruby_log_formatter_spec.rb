# coding: utf-8
require 'spec_helper'

describe LogAgent::Filter::RubyLogFormatter do
  let(:sink) { mock("MySinkObject", :<< => nil) }
  let(:filter) { LogAgent::Filter::RubyLogFormatter.new sink }
  
  it "should be created with new <sink>" do
    filter.sink.should == [sink]
  end

  describe "parsing" do
    load_entries!('ruby_log_formatter_entries')

    it "should pass the entry through to the sink" do
      sink.should_receive(:<<).with(entry1)
      filter << entry1
    end

    it "should parse the milliseconds" do
      ("%.6f" % (entry1.timestamp.to_f % 1.0)).should == "0.156196"
    end

    it "should always parse the timestamp as UTC" do
      # Since it's not specified, we presume the timestamp is UTC
      fake_local_timezone("UTC-9") do
        entry1.timestamp.strftime('%Y-%m-%d %H:%M:%S.%6N %z').should == '2013-05-21 12:02:45.156196 +0000'
      end
    end

    it "should use the timestamp as a better captured_at field" do
      entry1.captured_at.should == entry1.timestamp
    end

    it "should strip the prefix from the message" do
      entry1.message.should == 'Started GET "/" for 127.0.0.1 at 2013-05-21 12:02:46 +0100'
    end

    it "should strip the prefix from the message even if the timestamp doesn't parse" do
      entry2.message.should == 'Started GET "/" for 127.0.0.1 at 2013-05-21 12:02:46 +0100'
    end

    it "should extract the pid field" do
      entry1.fields['pid'].should == "12132"
      entry2.fields['pid'].should == "9987"
    end

    it "should parse debug statements too (which have different whitespace!)" do
      entry3.fields['pid'].should == "10308"
    end
  end
end

