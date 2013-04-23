require 'spec_helper'

describe LogAgent::Filter::Ossec, "ossec filter" do

  let(:sink) { mock('MySinkObject', :<< => nil) }
  let(:filter) { LogAgent::Filter::Ossec.new sink }

  load_entries!('ossec_entries')

  it "should extract the timestamp" do
    entry1.timestamp.should == Time.at(1366708323.11720175)
    entry2.timestamp.should == Time.at(1366708196.11701120)
  end

  it "should extract the tags" do
    entry1.fields['ossec_tags'].sort.should == %w(syslog sshd invalid_login authentication_failed).sort
    entry2.fields['ossec_tags'].sort.should == %w(syslog pam).sort
  end
  it "should extract the rule id" do
    entry1.fields['ossec_rule_id'].should == 5710
    entry2.fields['ossec_rule_id'].should == 5502
  end

  it "should extract the rule level" do
    entry1.fields['ossec_rule_level'].should == 5
    entry2.fields['ossec_rule_level'].should == 3
  end

  it "should extract the rule description" do
    entry1.fields['ossec_rule_description'].should == 'Attempt to login using a non-existent user'
    entry2.fields['ossec_rule_description'].should == 'Login session closed.'
  end

  it "should extract the source host" do
    entry1.fields['ossec_hostname'].should == 'web1.staging.freeagentcentral.net'
    entry2.fields['ossec_hostname'].should == 'rmq2-gc.integration.freeagentcentral.net'
  end

  it "should extract the source ip if available" do
    entry1.fields['ossec_src_ip'].should == "218.6.224.125"
    entry2.fields['ossec_src_ip'].should be_nil
  end

  it "should extract the username if available" do
    entry1.fields['ossec_username'].should be_nil
    entry2.fields['ossec_username'].should == 'replication'
  end

end