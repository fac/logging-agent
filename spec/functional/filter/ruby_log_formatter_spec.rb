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

    it "should parse timestamps correctly with ms" do
      # Set to be UTC here so tests pass irrespective of machine TZ
      # as timestamp contains no offset
      ENV['TZ'] = 'UTC'
      entry1.timestamp.utc.strftime('%Y-%m-%d %H:%M:%S.%6N UTC').should == '2013-05-21 12:02:45.156196 UTC'
    end

    it "should strip the timestamp from the message" do
      entry1.message.should == 'Started GET "/" for 127.0.0.1 at 2013-05-21 12:02:46 +0100'
    end
  end
end

