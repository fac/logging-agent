# coding: utf-8
require 'spec_helper'

describe LogAgent::Filter::DelayedJob do
  let(:sink) { mock("MySinkObject", :<< => nil) }
  let(:filter) { LogAgent::Filter::DelayedJob.new sink }

  it "should be created with new <sink>" do
    filter.sink.should == [sink]
  end

  describe "parsing" do
    load_entries!('delayed_job_entries')

    it "should pass the entry through to the sink" do
      sink.should_receive(:<<).with(entry1)
      filter << entry1
    end

    it "should mark the final entry as primary" do
      entry1.primary.should == nil
      entry2.primary.should == true
    end
  end
end
