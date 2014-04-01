require 'spec_helper'

describe LogAgent::Filter::MysqlSlow do
  let(:sink) { mock('MySinkObject', :<< => nil) }
  let(:bufsize) { 10 }
  let(:filter) { LogAgent::Filter::MysqlSlow.new sink, :bufsize => bufsize }

  it 'should be created with new <sink>' do
    filter.sink.should == [sink]
  end

  describe 'parsing' do
    load_entries!('mysql_slow_entries')

    it 'should pass the entries through to the sink' do
      sink.should_receive(:<<).with(entry1)
      filter << entry1
      sink.should_receive(:<<).with(entry2)
      filter << entry2
      sink.should_receive(:<<).exactly(2).times.with(an_instance_of(LogAgent::Event))
      filter << entry3
    end

    it 'should restrict length of message to @bufsize' do
      sink.should_receive(:<<) { |event|
        event.message.length.should <= bufsize
      }
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
        entry3.timestamp.to_s.should =~ /^2014-03-31 14:05:29/
      end
    end

    it 'should parse the timestamp as UTC' do
      entry1.timestamp.zone.should == 'UTC'
      entry2.timestamp.zone.should == 'UTC'
      entry3.timestamp.zone.should == 'UTC'
    end

    it 'should parse the user correctly if avaliable' do
      entry1.fields['mysql_slow_user'].should be_nil
      entry2.fields['mysql_slow_user'].should == 'bob'
      entry3.fields['mysql_slow_user'].should == 'alice'
    end

    it 'should parse the ip address correctly if avaliable' do
      entry1.fields['mysql_slow_ip'].should be_nil
      entry2.fields['mysql_slow_ip'].should == '10.11.11.11'
      entry3.fields['mysql_slow_ip'].should == '10.11.11.12'
    end

    it 'should parse the query time correctly if avaliable' do
      entry1.fields['mysql_slow_query_time'].should be_nil
      entry2.fields['mysql_slow_query_time'].should == 3
      entry3.fields['mysql_slow_query_time'].should == 3
    end

    it 'should parse the lock time correctly if avaliable' do
      entry1.fields['mysql_slow_lock_time'].should be_nil
      entry2.fields['mysql_slow_lock_time'].should == 0
      entry3.fields['mysql_slow_lock_time'].should == 0
    end

    it 'should parse the rows sent correctly if avaliable' do
      entry1.fields['mysql_slow_rows_sent'].should be_nil
      entry2.fields['mysql_slow_rows_sent'].should == 2
      entry3.fields['mysql_slow_rows_sent'].should == 2
    end

    it 'should parse the rows examined correctly if avaliable' do
      entry1.fields['mysql_slow_rows_examined'].should be_nil
      entry2.fields['mysql_slow_rows_examined'].should == 322814
      entry3.fields['mysql_slow_rows_examined'].should == 3224
    end
  end
end
