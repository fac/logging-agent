# coding: utf-8
require 'spec_helper'

describe LogAgent::Filter::PtTableChecksum do
  let(:filter) { described_class.new(sink) }

  let(:sink) { mock('MySinkObject', :<< => nil) }

  it 'should be created with new <sink>' do
    filter.sink.should == [sink]
  end

  describe 'parsing' do
    load_entries!('pt_table_checksums')

    it 'should pass the entry through to the sink' do
      sink.should_receive(:<<).with(entry1)
      filter << entry1
    end

    it 'should parse the timestamp correctly' do
      Timecop.freeze(Time.parse('2018-10-18 09:19:20 UTC')) do
        entry1.timestamp.utc.to_s.should == '2018-10-18 09:19:20 UTC'
        entry2.timestamp.utc.to_s.should == '2018-10-18 09:19:20 UTC'
        entry3.timestamp.utc.to_s.should == '2018-10-17 13:17:54 UTC'
        entry4.timestamp.utc.to_s.should == '2018-10-17 13:17:54 UTC'
        entry5.timestamp.utc.to_s.should == '2018-10-10 11:23:55 UTC'
        entry6.timestamp.utc.to_s.should == '2018-10-18 09:19:20 UTC'
        entry7.timestamp.utc.to_s.should == '2018-10-17 00:31:09 UTC'
        entry8.timestamp.utc.to_s.should == '2018-10-18 09:19:20 UTC'
      end
    end

    it 'should parse the table' do
      entry1.fields['table'].should be_nil
      entry2.fields['table'].should be_nil
      entry3.fields['table'].should == 'mysql.columns_priv'
      entry4.fields['table'].should == 'mysql.help_category'
      entry5.fields['table'].should == 'my_database.my_table'
      entry6.fields['table'].should == 'my_database.my_table'
      entry7.fields['table'].should == 'my_database.my_table'
      entry8.fields['table'].should == 'my_database.my_table'
    end

    it 'should parse the error count' do
      entry3.fields['errors'].should == 0
      entry4.fields['errors'].should == 1
    end

    it 'should parse the diffs count' do
      entry3.fields['diffs'].should == 0
      entry4.fields['diffs'].should == 3
    end

    it 'should parse the row count' do
      entry3.fields['rows'].should == 0
      entry4.fields['rows'].should == 40
    end

    it 'should parse the chunk count' do
      entry3.fields['chunks'].should == 1
      entry4.fields['chunks'].should == 8
    end

    it 'should parse the skipped count' do
      entry3.fields['skipped'].should == 1
      entry4.fields['skipped'].should == 0
    end

    it 'should parse the time' do
      entry3.fields['time_elapsed'].should == '0.003'
      entry4.fields['time_elapsed'].should == '0.003'
    end
  end
end
