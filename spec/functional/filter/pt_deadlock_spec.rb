# coding: utf-8
require 'spec_helper'

describe LogAgent::Filter::PtDeadlock do
  let(:sink) { mock('MySinkObject', :<< => nil) }
  let(:filter) { LogAgent::Filter::PtDeadlock.new sink }

  it 'should be created with new <sink>' do
    filter.sink.should == [sink]
  end

  describe 'parsing' do
    load_entries!('pt_deadlock_entries')

    it 'should pass the entry through to the sink' do
      sink.should_receive(:<<).with(entry1)
      filter << entry1
    end

    it 'should parse the timtestamp correctly' do
      # the file actually contains "18:30" but without timezone qualifier, so we use the
      # local system timezone to work out what is displayed. Either way, we should omit UTC
      # with a timezone qualifier (hence the comparison to UTC)
      entry1.timestamp.utc.should == Time.local(2013,4,23, 18,30,04)
      entry2.timestamp.utc.should == Time.local(2013,5,8,  13,02,31)
    end

    it 'should parse the server' do
      entry1.fields['pt_deadlock_tx1']['server'].should == 'localhost'
      entry1.fields['pt_deadlock_tx2']['server'].should == 'localhost'
      entry2.fields['pt_deadlock_tx1']['server'].should == 'localhost'
      entry2.fields['pt_deadlock_tx2']['server'].should == 'localhost'
    end

    it 'should parse the thread' do
      entry1.fields['pt_deadlock_tx1']['thread'].should == 262
      entry1.fields['pt_deadlock_tx2']['thread'].should == 267
      entry2.fields['pt_deadlock_tx1']['thread'].should == 1334961
      entry2.fields['pt_deadlock_tx2']['thread'].should == 1334965
    end

    it 'should parse the txn_id' do
      entry1.fields['pt_deadlock_tx1']['txn_id'].should == 0
      entry1.fields['pt_deadlock_tx2']['txn_id'].should == 0
      entry2.fields['pt_deadlock_tx1']['txn_id'].should == 1297146036
      entry2.fields['pt_deadlock_tx2']['txn_id'].should == 1297145424
    end

    it 'should parse the txn_time' do
      entry1.fields['pt_deadlock_tx1']['txn_time'].should == 5
      entry1.fields['pt_deadlock_tx2']['txn_time'].should == 3
      entry2.fields['pt_deadlock_tx1']['txn_time'].should == 0
      entry2.fields['pt_deadlock_tx2']['txn_time'].should == 1
    end

    it 'should parse the user' do
      entry1.fields['pt_deadlock_tx1']['user'].should == 'root'
      entry1.fields['pt_deadlock_tx2']['user'].should == 'root'
      entry2.fields['pt_deadlock_tx1']['user'].should == 'myuser'
      entry2.fields['pt_deadlock_tx2']['user'].should == 'myuser'
    end

    it 'should parse the hostname' do
      entry1.fields['pt_deadlock_tx1']['hostname'].should == 'localhost'
      entry1.fields['pt_deadlock_tx2']['hostname'].should == 'localhost'
      entry2.fields['pt_deadlock_tx1']['hostname'].should == ''
      entry2.fields['pt_deadlock_tx2']['hostname'].should == ''
    end

    it 'should parse the ip' do
      entry1.fields['pt_deadlock_tx1']['ip'].should == ''
      entry1.fields['pt_deadlock_tx2']['ip'].should == ''
      entry2.fields['pt_deadlock_tx1']['ip'].should == '10.0.0.63'
      entry2.fields['pt_deadlock_tx2']['ip'].should == '10.0.0.63'
    end

    it 'should parse the db' do
      entry1.fields['pt_deadlock_tx1']['db'].should == 'deadlock_test'
      entry1.fields['pt_deadlock_tx2']['db'].should == 'deadlock_test'
      entry2.fields['pt_deadlock_tx1']['db'].should == 'mydb'
      entry2.fields['pt_deadlock_tx2']['db'].should == 'mydb'
    end

    it 'should parse the tbl' do
      entry1.fields['pt_deadlock_tx1']['tbl'].should == 'mytable'
      entry1.fields['pt_deadlock_tx2']['tbl'].should == 'mytable_items'
      entry2.fields['pt_deadlock_tx1']['tbl'].should == 'mytable_items'
      entry2.fields['pt_deadlock_tx2']['tbl'].should == 'mytable_items'
    end

    it 'should parse the idx' do
      entry1.fields['pt_deadlock_tx1']['idx'].should == 'PRIMARY'
      entry1.fields['pt_deadlock_tx2']['idx'].should == 'index_mytable_items_on_mytable_id'
      entry2.fields['pt_deadlock_tx1']['idx'].should == 'index_mytable_items_on_mytable_id'
      entry2.fields['pt_deadlock_tx2']['idx'].should == ''
    end

    it 'should parse the lock_type' do
      entry1.fields['pt_deadlock_tx1']['lock_type'].should == 'RECORD'
      entry1.fields['pt_deadlock_tx2']['lock_type'].should == 'RECORD'
      entry2.fields['pt_deadlock_tx1']['lock_type'].should == 'RECORD'
      entry2.fields['pt_deadlock_tx2']['lock_type'].should == 'TABLE'
    end

    it 'should parse the lock_mode' do
      entry1.fields['pt_deadlock_tx1']['lock_mode'].should == 'X'
      entry1.fields['pt_deadlock_tx2']['lock_mode'].should == 'X'
      entry2.fields['pt_deadlock_tx1']['lock_mode'].should == 'X'
      entry2.fields['pt_deadlock_tx2']['lock_mode'].should == 'AUTO-INC'
    end

    it 'should parse the wait_hold' do
      entry1.fields['pt_deadlock_tx1']['wait_hold'].should == 'w'
      entry1.fields['pt_deadlock_tx2']['wait_hold'].should == 'w'
      entry2.fields['pt_deadlock_tx1']['wait_hold'].should == 'w'
      entry2.fields['pt_deadlock_tx2']['wait_hold'].should == 'w'
    end

    it 'should parse the victim' do
      entry1.fields['pt_deadlock_tx1']['victim'].should == 0
      entry1.fields['pt_deadlock_tx2']['victim'].should == 1
      entry2.fields['pt_deadlock_tx1']['victim'].should == 1
      entry2.fields['pt_deadlock_tx2']['victim'].should == 0
    end

    it 'should parse the query' do
      entry1.fields['pt_deadlock_tx1']['query'].should == 'UPDATE `mytable` SET `value` = 100.0 WHERE `mytable`.`id` = 2'
      entry1.fields['pt_deadlock_tx2']['query'].should == 'INSERT INTO mytable_items (mytable_id, price) VALUES (1, 0.99)'
      entry2.fields['pt_deadlock_tx1']['query'].should == "UPDATE `mytable` SET `value` = 'some\\r\\nstuff' WHERE `mytable`.`id` = 2"
      entry2.fields['pt_deadlock_tx2']['query'].should == "INSERT INTO mytable_items (mytable_id, price) VALUES (1, 0.99)"
    end
  end
end
