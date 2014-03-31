require 'spec_helper'

describe LogAgent::Filter::MysqlSlow do
  let(:sink) { mock('MySinkObject', :<< => nil) }
  let(:filter) { LogAgent::Filter::MysqlSlow.new sink }

  it 'should be created with new <sink>' do
    filter.sink.should == [sink]
  end

  describe 'parsing' do
    load_entries!('mysql_slow_entries')

    it 'should pass the entry through to the sink' do
      sink.should_receive(:<<).with(entry1)
      filter << entry1
    end

    it 'should use the current time when not found in log' do
      Timecop.freeze do
        entry1.timestamp.should == Time.now
      end
    end

    it 'should parse the timestamp correctly' do
      Timecop.freeze(Time.local(2014, 03, 31, 00, 00, 00)) do
        entry2.timestamp.to_s.should =~ /^2014-03-31 14:05:29/
      end
    end

    it 'should parse the timestamp as UTC' do
      entry1.timestamp.zone.should == 'UTC'
      entry2.timestamp.zone.should == 'UTC'
    end

    it 'should parse the user correctly if avaliable' do
      entry1.fields['mysql_slow_user'].should be_nil
      entry2.fields['mysql_slow_user'].should == 'bob'
    end

    it 'should parse the ip address correctly if avaliable' do
      entry1.fields['mysql_slow_ip'].should be_nil
      entry2.fields['mysql_slow_ip'].should == '10.11.11.11'
    end

    it 'should parse the query time correctly if avaliable' do
      entry1.fields['mysql_slow_query_time'].should be_nil
      entry2.fields['mysql_slow_query_time'].should == 3
    end

    it 'should parse the lock time correctly if avaliable' do
      entry1.fields['mysql_slow_lock_time'].should be_nil
      entry2.fields['mysql_slow_lock_time'].should == 0
    end

    it 'should parse the rows sent correctly if avaliable' do
      entry1.fields['mysql_slow_rows_sent'].should be_nil
      entry2.fields['mysql_slow_rows_sent'].should == 2
    end

    it 'should parse the rows examined correctly if avaliable' do
      entry1.fields['mysql_slow_rows_examined'].should be_nil
      entry2.fields['mysql_slow_rows_examined'].should == 322814
    end
  end
end
