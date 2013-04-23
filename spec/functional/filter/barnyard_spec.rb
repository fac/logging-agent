# coding: utf-8
require 'spec_helper'

describe LogAgent::Filter::Barnyard do
  let(:sink) { mock('MySinkObject', :<< => nil) }
  let(:filter) { LogAgent::Filter::Barnyard.new sink }
  
  it 'should be created with new <sink>' do
    filter.sink.should == [sink]
  end

  describe 'parsing' do
    load_entries!('barnyard_entries')

    it 'should pass the entry through to the sink' do
      sink.should_receive(:<<).with(entry1)
      filter << entry1
    end
    
    it 'should parse the timestamp correctly' do
      Timecop.freeze(Time.local(2013, 04, 01, 00, 00, 00)) do
        entry1.timestamp.to_s.should =~ /^2013-03-22 12:43:42/
        entry2.timestamp.to_s.should =~ /^2013-03-22 12:43:34/
        entry3.timestamp.to_s.should =~ /^2013-04-02 11:18:04/
        entry5.timestamp.to_s.should =~ /^2013-03-22 01:24:25/
      end
    end

    it "should parse the timestamp as UTC" do
      Timecop.freeze(Time.local(2013, 04, 01, 00, 00, 00)) do
        entry1.timestamp.zone.should == "UTC"
        entry2.timestamp.zone.should == "UTC"
        entry3.timestamp.zone.should == "UTC"
        entry5.timestamp.zone.should == "UTC"
      end
    end 

    it 'should use the current time if log timestamp is invalid' do
      Timecop.freeze do
        entry4.timestamp.should == Time.now
      end
    end

    it 'should parse the generator id' do
      entry1.fields['barnyard_gen_id'].should == 129
      entry2.fields['barnyard_gen_id'].should == 3
      entry3.fields['barnyard_gen_id'].should == 139
      entry4.fields['barnyard_gen_id'].should == 2
      entry5.fields['barnyard_gen_id'].should == 0
    end

    it 'should parse the signature id' do
      entry1.fields['barnyard_sig_id'].should == 14
      entry2.fields['barnyard_sig_id'].should == 19187
      entry3.fields['barnyard_sig_id'].should == 1
      entry4.fields['barnyard_sig_id'].should == 15
      entry5.fields['barnyard_sig_id'].should == 88
    end

    it 'should parse the signature revision' do
      entry1.fields['barnyard_sig_rev'].should == 1
      entry2.fields['barnyard_sig_rev'].should == 2
      entry3.fields['barnyard_sig_rev'].should == 1
      entry4.fields['barnyard_sig_rev'].should == 88
      entry5.fields['barnyard_sig_rev'].should == 6
    end

    it 'should parse the description' do
      entry1.fields['barnyard_desc'].should == 'stream5: TCP Timestamp is missing'
      entry2.fields['barnyard_desc'].should == 'BAD-TRAFFIC TMG Firewall Client long host entry exploit attempt'
      entry3.fields['barnyard_desc'].should == 'sensitive_data: sensitive data global threshold exceeded'
      entry4.fields['barnyard_desc'].should == 'Snort Alert [2:15:88]'
      entry5.fields['barnyard_desc'].should == 'Snort Alert [0:88:6]'
    end

    it 'should parse the classification' do
      entry1.fields['barnyard_class'].should == 'Potentially Bad Traffic'
      entry2.fields['barnyard_class'].should == 'Attempted User Privilege Gain'
      entry3.fields['barnyard_class'].should == 'Sensitive Data was Transmitted Across the Network'
      entry4.fields['barnyard_class'].should == '0'
      entry5.fields['barnyard_class'].should be_nil
    end

    it 'should parse the priority' do
      entry1.fields['barnyard_priority'].should == 2
      entry2.fields['barnyard_priority'].should == 1
      entry3.fields['barnyard_priority'].should == 2
      entry4.fields['barnyard_priority'].should == 5
      entry5.fields['barnyard_priority'].should be_nil
    end

    it 'should parse the protocol' do
      entry1.fields['barnyard_proto'].should == 'TCP'
      entry2.fields['barnyard_proto'].should == 'UDP'
      entry3.fields['barnyard_proto'].should == 'PROTO:254'
      entry4.fields['barnyard_proto'].should == 'TCP'
      entry5.fields['barnyard_proto'].should be_nil
    end

    it 'should parse the source ip' do
      entry1.fields['barnyard_src_ip'].should == '192.168.1.1'
      entry2.fields['barnyard_src_ip'].should == '192.168.1.2'
      entry3.fields['barnyard_src_ip'].should == '192.168.1.3'
      entry4.fields['barnyard_src_ip'].should == '192.168.1.4'
      entry5.fields['barnyard_src_ip'].should be_nil
    end

    it 'should parse the source port' do
      entry1.fields['barnyard_src_port'].should == 52828
      entry2.fields['barnyard_src_port'].should == 53
      entry3.fields['barnyard_src_port'].should be_nil
      entry4.fields['barnyard_src_port'].should == 443
      entry5.fields['barnyard_src_port'].should be_nil
    end
    
    it 'should parse the destination ip' do
      entry1.fields['barnyard_dest_ip'].should == '10.0.1.1'
      entry2.fields['barnyard_dest_ip'].should == '10.0.1.2'
      entry3.fields['barnyard_dest_ip'].should == '10.0.1.3'
      entry4.fields['barnyard_dest_ip'].should == '10.0.1.4'
      entry5.fields['barnyard_dest_ip'].should be_nil
    end

    it 'should parse the destination port' do
      entry1.fields['barnyard_dest_port'].should be_nil
      entry2.fields['barnyard_dest_port'].should == 59788
      entry3.fields['barnyard_dest_port'].should be_nil
      entry4.fields['barnyard_dest_port'].should == 49367
      entry5.fields['barnyard_dest_port'].should be_nil
    end
  end
end
