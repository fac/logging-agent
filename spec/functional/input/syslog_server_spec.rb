require 'spec_helper'

describe LogAgent::Input::SyslogServer do
  include EventedSpec::EMSpec

  let(:sink) { mock("FileTailSink", :<< => nil) }  
  let(:syslog_server) { LogAgent::Input::SyslogServer.new sink, :port => 9977, :tags => ['tag_a', 'tag_b'] }

  let(:source) { EventMachine.open_datagram_socket('127.0.0.1', 0) }

  em_before do
    syslog_server
  end

  it "should emit a callback" do
    syslog_server.callback do 
      done
    end
  end
  it "should emit a message for each UDP datagram received on the specified port" do
    sink.should_receive(:<<) { done }
    source.send_datagram('foobar', '127.0.0.1', 9977)
  end
  
  it "should set the tags on outgoing messages" do
    syslog_server.parse('foo bar').tags.should == ['tag_a', 'tag_b']
    done
  end
  describe "SyslogServer#parse with unrecognised type" do
    let(:example) { syslog_server.parse("sdfkjhsefkjh3r2w 4riuhfhj I'm a bunch of gibberish!")}
    it "should set the message to the datagram contents" do
      example.message.should == %(sdfkjhsefkjh3r2w 4riuhfhj I'm a bunch of gibberish!)
      done
    end
    it "should set the timestamp to the received time" do
      example.timestamp.should be_a(Time)
      done
    end
  end

  describe "Input::SyslogServer#parse, handling examples from RFC5424" do
    let(:example1) { syslog_server.parse("<34>1 2003-10-11T22:14:15.003Z mymachine.example.com su - ID47 - 'su root' failed for lonvick on /dev/pts/8") }
    # 
    # In this example, the VERSION is 1 and the Facility has the value of
    # 4.  The Severity is 2.  The message was created on 11 October 2003 at
    # 10:14:15pm UTC, 3 milliseconds into the next second.  The message
    # originated from a host that identifies itself as
    # "mymachine.example.com".  The APP-NAME is "su" and the PROCID is
    # unknown.  The MSGID is "ID47".  The MSG is "'su root' failed for
    # lonvick...", encoded in UTF-8.  The encoding is defined by the BOM.
    # There is no STRUCTURED-DATA present in the message; this is indicated
    # by "-" in the STRUCTURED-DATA field.
    it "should extract the appropriate fields from example1" do
      example1.type.should == 'syslog'
      example1.source_type.should == 'syslog'
      example1.timestamp.should == Time.parse('2003-10-11T22:14:15.003Z')
      example1.fields['syslog_version'].should == 1
      example1.fields['syslog_facility'].should == 4
      example1.fields['syslog_severity'].should == 'critical'
      example1.fields['syslog_hostname'].should == 'mymachine.example.com'
      example1.fields['syslog_app_name'].should == 'su'
      example1.fields['syslog_proc_id'].should == nil
      example1.fields['syslog_msg_id'].should == 'ID47'
      example1.fields['syslog_message'].should == %('su root' failed for lonvick on /dev/pts/8)
      done
    end
    it "should set a message format" do
      example1.message.should == "Oct 11 22:14:15 mymachine.example.com su: 'su root' failed for lonvick on /dev/pts/8"
      done
    end

    let(:example2) { syslog_server.parse("<165>1 2003-08-24T05:14:15.000003-07:00 192.0.2.1 myproc 8710 - - %% It's time to make the do-nuts.") }
    # In this example, the VERSION is again 1.  The Facility is 20, the
    # Severity 5.  The message was created on 24 August 2003 at 5:14:15am,
    # with a -7 hour offset from UTC, 3 microseconds into the next second.
    # The HOSTNAME is "192.0.2.1", so the syslog application did not know
    # its FQDN and used one of its IPv4 addresses instead.  The APP-NAME is
    # "myproc" and the PROCID is "8710" (for example, this could be the
    # UNIX PID).  There is no STRUCTURED-DATA present in the message; this
    # is indicated by "-" in the STRUCTURED-DATA field.  There is no
    # specific MSGID and this is indicated by the "-" in the MSGID field.
    # The message is "%% It's time to make the do-nuts.".  As the Unicode
    # BOM is missing, the syslog application does not know the encoding of
    # the MSG part.
    it "should extract the appropriate fields from example1" do
      example2.type.should == 'syslog'
      example2.timestamp.should == Time.parse('2003-08-24T05:14:15.000003-07:00')
      example2.fields['syslog_version'].should == 1
      example2.fields['syslog_facility'].should == 20
      example2.fields['syslog_severity'].should == 'notice'
      example2.fields['syslog_hostname'].should == '192.0.2.1'
      example2.fields['syslog_app_name'].should == 'myproc'
      example2.fields['syslog_proc_id'].should == '8710'
      example2.fields['syslog_msg_id'].should == nil
      example2.fields['syslog_message'].should == %(%% It's time to make the do-nuts.)
      done
    end
    it "should set a message format" do
      example2.message.should == "Aug 24 13:14:15 192.0.2.1 myproc[8710]: %% It's time to make the do-nuts."
      done
    end

    let(:example3) { syslog_server.parse(%(<165>1 2003-10-11T22:14:15.003Z mymachine.example.com evntslog - ID47 [exampleSDID@32473 iut="3" eventSource="Application" eventID="1011"] An application event log entry...)) }
    # This example is modeled after Example 1.  However, this time it
    # contains STRUCTURED-DATA, a single element with the value
    # "[exampleSDID@32473 iut="3" eventSource="Application"
    # eventID="1011"]".  The MSG itself is "An application event log
    # entry..."  The BOM at the beginning of MSG indicates UTF-8 encoding.
    it "should extract the appropriate fields from example1" do
      example3.type.should == 'syslog'
      example3.timestamp.should == Time.parse('2003-10-11T22:14:15.003Z')
      example3.fields['syslog_version'].should == 1
      example3.fields['syslog_facility'].should == 20
      example3.fields['syslog_severity'].should == 'notice'
      example3.fields['syslog_hostname'].should == 'mymachine.example.com'
      example3.fields['syslog_app_name'].should == 'evntslog'
      example3.fields['syslog_proc_id'].should == nil
      example3.fields['syslog_msg_id'].should == 'ID47'
      example3.fields['syslog_message'].should == %([exampleSDID@32473 iut="3" eventSource="Application" eventID="1011"] An application event log entry...)
      done
    end
    it "should set a message format" do
      example3.message.should == 'Oct 11 22:14:15 mymachine.example.com evntslog: [exampleSDID@32473 iut="3" eventSource="Application" eventID="1011"] An application event log entry...'
      done
    end

    let(:example4) { syslog_server.parse(%(<165>1 2003-10-11T22:14:15.003Z mymachine.example.com evntslog - ID47 [exampleSDID@32473 iut="3" eventSource="Application" eventID="1011"][examplePriority@32473 class="high"]))}
    # This example shows a message with only STRUCTURED-DATA and no MSG
    # part.  This is a valid message.
    it "should extract the appropriate fields from example1" do
      example4.type.should == 'syslog'
      example4.timestamp.should == Time.parse('2003-10-11T22:14:15.003Z')
      example4.fields['syslog_version'].should == 1
      example4.fields['syslog_facility'].should == 20
      example4.fields['syslog_severity'].should == 'notice'
      example4.fields['syslog_hostname'].should == 'mymachine.example.com'
      example4.fields['syslog_app_name'].should == 'evntslog'
      example4.fields['syslog_proc_id'].should == nil
      example4.fields['syslog_msg_id'].should == 'ID47'
      example4.fields['syslog_message'].should == '[exampleSDID@32473 iut="3" eventSource="Application" eventID="1011"][examplePriority@32473 class="high"]'
      done
    end
    it "should set a message format" do
      example4.message.should == 'Oct 11 22:14:15 mymachine.example.com evntslog: [exampleSDID@32473 iut="3" eventSource="Application" eventID="1011"][examplePriority@32473 class="high"]'
      done
    end

    it "should all emit Event objects" do
      example1.should be_a(LogAgent::Event)
      example2.should be_a(LogAgent::Event)
      example3.should be_a(LogAgent::Event)
      example4.should be_a(LogAgent::Event)
      done
    end
  end
  
  describe "SyslogServer#parse for the servers' format from rsyslog" do
    describe "for syslog entries with process-ids values" do
      let(:example1) { syslog_server.parse("<86>Feb  12 21:04:59 web1.server.net sshd[1576]: Received disconnect from 10.0.0.1: 11: disconnected by user") }
      it "should parse the facility and severity" do
        example1.fields['syslog_facility'].should == 10
        example1.fields['syslog_severity'].should == 'informational'
        done
      end
      it "should parse the date, presuming the year is the current one" do
        example1.timestamp.month.should == 2
        example1.timestamp.day.should == 12
        example1.timestamp.year.should == Time.now.year
        example1.timestamp.hour.should == 21
        example1.timestamp.min.should == 04
        example1.timestamp.sec.should == 59
        done
      end
      it "should parse the hostname" do
        example1.fields['syslog_hostname'].should == 'web1.server.net'
        done
      end
      it "should parse the process name and id" do
        example1.fields['syslog_app_name'].should == 'sshd'
        example1.fields['syslog_proc_id'].should == '1576'
        done
      end
      it "should parse the message" do
        example1.fields['syslog_message'].should == 'Received disconnect from 10.0.0.1: 11: disconnected by user'
        done
      end
      it "should display the original message message" do
        example1.message.should == 'Feb  12 21:04:59 web1.server.net sshd[1576]: Received disconnect from 10.0.0.1: 11: disconnected by user'
        done
      end

      let(:example2) { syslog_server.parse("<78>Mar  3 21:05:01 web1.server.net crond[1624]: (root) CMD (/usr/bin/gmetric --name=foo --value=4 --type=uint32 --units=unit --tmax=60 --dmax=120)")}
      it "should parse the fields" do
        example2.fields['syslog_facility'].should == 9
        example2.fields['syslog_severity'].should == 'informational'
        example2.timestamp.month.should == 3
        example2.timestamp.day.should == 3
        example2.timestamp.year.should == Time.now.year
        example2.timestamp.hour.should == 21
        example2.timestamp.min.should == 05
        example2.timestamp.sec.should == 01
        example2.fields['syslog_hostname'].should == 'web1.server.net'
        example2.fields['syslog_app_name'].should == 'crond'
        example2.fields['syslog_proc_id'].should == '1624'
        example2.fields['syslog_message'].should == '(root) CMD (/usr/bin/gmetric --name=foo --value=4 --type=uint32 --units=unit --tmax=60 --dmax=120)'
        done
      end
    end
    describe "for syslog entries without process-id values" do
      let(:example) { syslog_server.parse("<85>Mar  3 21:04:58 web1.server.net su: pam_unix(su:auth): authentication failure; logname=thomas uid=2005 euid=0 tty=pts/1 ruser=thomas rhost=  user=root")}
      it "should parse the fields" do
        example.fields['syslog_facility'].should == 10
        example.fields['syslog_severity'].should == 'notice'
        example.timestamp.month.should == 3
        example.timestamp.day.should == 3
        example.timestamp.year.should == Time.now.year
        example.timestamp.hour.should == 21
        example.timestamp.min.should == 4
        example.timestamp.sec.should == 58
        example.fields['syslog_hostname'].should == 'web1.server.net'
        example.fields['syslog_app_name'].should == 'su'
        example.fields['syslog_proc_id'].should be_nil
        example.fields['syslog_message'].should == 'pam_unix(su:auth): authentication failure; logname=thomas uid=2005 euid=0 tty=pts/1 ruser=thomas rhost=  user=root'
        done
      end
      
    end
  end
  
end

