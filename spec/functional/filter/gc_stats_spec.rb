# coding: utf-8
require 'spec_helper'

describe LogAgent::Filter::GcStats do
  let(:sink) { mock("MySinkObject", :<< => nil) }
  let(:filter) { LogAgent::Filter::GcStats.new sink }

  it "should be created with new <sink>" do
    filter.sink.should == [sink]
  end

  describe "parsing" do
    load_entries!('rails_entries')

    it "should pass the entry through to the sink" do
      sink.should_receive(:<<).with(entry1)
      filter << entry1
    end

    it "should add the GC stats as fields" do
      entry8.fields['major_gc_total'].should == 190
      entry8.fields['major_gc'].should == 0
      entry8.fields['minor_gc_total'].should == 1353
      entry8.fields['minor_gc'].should == 0
      entry8.fields['object_allocations'].should == 8398
      entry8.fields['live_slots_total'].should == 1877377
      entry8.fields['live_slots'].should == 8398
      entry8.fields['total_slots_total'].should == 2625715
      entry8.fields['total_slots'].should == 0
      entry8.fields['oldmalloc_bytes_total'].should == 12750672
      entry8.fields['oldmalloc_bytes'].should == 377920
    end
  end
end
