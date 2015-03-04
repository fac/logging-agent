# coding: utf-8
require 'spec_helper'

describe LogAgent::Filter::Rails do
  let(:sink) { mock("MySinkObject", :<< => nil) }
  let(:filter) { LogAgent::Filter::Rails.new sink }
  
  it "should be created with new <sink>" do
    filter.sink.should == [sink]
  end

  describe "parsing" do
    load_entries!('rails_entries')

    it "should pass the entry through to the sink" do
      sink.should_receive(:<<).with(entry1)
      filter << entry1
    end

    it "should parse timestamps correctly" do
      entry1.timestamp.utc.to_s.should == '2012-03-04 00:01:22 UTC'
      entry2.timestamp.utc.to_s.should == '2012-03-04 00:01:22 UTC'
      entry3.timestamp.utc.to_s.should == '2012-03-04 00:01:22 UTC'
    end

    it "should parse timestamps in different timezones" do
      entry4.timestamp.utc.to_s.should == '2012-03-03 19:01:22 UTC'
    end

    it "should use the current time less the duration if log timestamp is invalid" do
      Timecop.freeze do
        entry5.timestamp.should == Time.now - (entry5.fields['rails_duration']['total'] / 1000)
      end
    end

    it "should use the current time if log timestamp is absent" do
      Timecop.freeze do
        entry6.timestamp.should == Time.now
      end
    end

    # Rails unhelpfully doesn't log the timestamp with precision greater than a second
    # so ordering of our logs goes a bit squiffy. So if there is a reasonable looking
    # :captured_at field, then use that, as it will have a higher precision.
    #
    it "should use the captured_at field if it is within 1 second of the timestamp" do
      Timecop.freeze(Time.parse('2012-03-04 00:01:22.12345 UTC')) do
        entry1.timestamp.utc.to_f.should == 1330819282.1114502  # 0.12345 - 0.012
      end
    end

    # If captured_at and timestamp disagree (i.e. we're reading old logs for some reason) then
    # make do with the less precice, but more accurate, timestamp field.
    it "should not use the captured_at field if it is outside 1 second of the rails timestamp" do
      Timecop.freeze(Time.parse('2012-03-04 00:01:25.12345 UTC')) do
        entry1.timestamp.utc.to_f.should == 1330819282.0
      end
    end

    # If we have a Rails log entry that took longer than one second, then the recorded timestamp
    # will be at the start of the request, but the captured_at at the end. Ensure we subtract the request duration
    # from the captured_at field when estimating the timestamp!
    it "should subtract the rails_duration from the captured_at field when estimating the precise timestamp" do
      # rails timestamp is 2013-04-23 08:03:10 +0000
      # duration is 16429ms
      fake_capture_time = Time.parse("2013-04-23 08:03:26 +0000") #i.e., roughly 16 seconds in the future

      Timecop.freeze(fake_capture_time) do
        entry7.timestamp.should == fake_capture_time - (entry7.fields['rails_duration']['total'] / 1000)
      end
    end
    
    it "should parse the method" do
      entry1.fields['rails_method'].should == 'GET'
      entry2.fields['rails_method'].should == 'GET'
      entry3.fields['rails_method'].should == 'GET'
      entry4.fields['rails_method'].should == 'POST'
      entry5.fields['rails_method'].should == 'GET'
      entry6.fields['rails_method'].should == 'GET'
    end

    it "should parse the path" do
      entry1.fields['rails_request_path'].should == "/invoices/1234/invoice_items/auto_complete_for_invoice_item_description?term=autocomplete+term&_=1330819280685"
      entry2.fields['rails_request_path'].should == "/signup"
      entry3.fields['rails_request_path'].should == "/invoices/3456"
      entry4.fields['rails_request_path'].should == "/sessions"
      entry5.fields['rails_request_path'].should == "/bank_accounts/1234/balance_history.csv"
      entry6.fields['rails_request_path'].should == "/company/income_data.xml"
    end

    it "should parse the IP address" do
      entry1.fields['rails_remote_addr'].should == "9.1.0.1"
      entry2.fields['rails_remote_addr'].should == "90.1.2.3"
      entry3.fields['rails_remote_addr'].should == "90.1.2.3"
      entry4.fields['rails_remote_addr'].should == "80.12.3.4"
      entry5.fields['rails_remote_addr'].should == "80.2.3.4"
      entry6.fields['rails_remote_addr'].should == "90.1.2.3"
    end
    
    it "should parse the controller" do
      entry1.fields['rails_controller'].should == "InvoiceItemsController"
      entry2.fields['rails_controller'].should == "SignupController"
      entry3.fields['rails_controller'].should == "InvoicesController"
      entry4.fields['rails_controller'].should == "SessionsController"
      entry5.fields['rails_controller'].should == "BankAccountsController"
      entry6.fields['rails_controller'].should == "CompaniesController"
    end
    it "should parse the action" do
      entry1.fields['rails_action'].should == "auto_complete_for_invoice_item_description"
      entry2.fields['rails_action'].should == "index"
      entry3.fields['rails_action'].should == "show"
      entry4.fields['rails_action'].should == "create"
      entry5.fields['rails_action'].should == "balance_history"
      entry6.fields['rails_action'].should == "income_data"
    end
    it "should parse the format (even if it's not present)" do
      entry1.fields['rails_format'].should == "JSON"
      entry2.fields['rails_format'].should == "HTML"
      entry3.fields['rails_format'].should == "HTML"
      entry4.fields['rails_format'].should be_nil
      entry5.fields['rails_format'].should == "CSV"
      entry6.fields['rails_format'].should == "XML"
    end
    xit "should parse the parameters" do
      entry1.fields['rails_params'].should == {"term"=>"The \"Term\"", "_"=>"1330819280685", "invoice_id"=>"1234"}
      entry2.fields['rails_params'].should == nil
      entry3.fields['rails_params'].should == {"id"=>"3456"}
      entry4.fields['rails_params'].should == {"utf8"=>"✓", "authenticity_token"=>"wcrVEyLHKJaN7tI8bBl9omr/3uYaG64qfWjlA/OUVVQ=", "email"=>"some@emailhere", "password"=>"[FILTERED]", "openid_identifier"=>"a slash \"\\\"", "commit"=>"Log in to your Account"}
      entry5.fields['rails_params'].should == {"id" => "1234"}
      entry6.fields['rails_params'].should == nil
    end
    it "should parse a redirection" do
      entry1.fields['rails_redirect'].should be_nil
      entry2.fields['rails_redirect'].should be_nil
      entry3.fields['rails_redirect'].should be_nil
      entry4.fields['rails_redirect'].should == 'https://subdomain2.freeagentcentral.com/'
      entry5.fields['rails_redirect'].should be_nil
      entry6.fields['rails_redirect'].should be_nil
      
    end
    it "should parse the views rendered" do
      entry1.fields['rails_rendered'].should == [{'name' => 'inline template', 'duration' => 0.5}]
      entry2.fields['rails_rendered'].should == [{'name' => 'shared/_flash.html.erb', 'duration' => 0.1}, {'name' => 'layouts/_head.html.erb', 'duration' => 0.1}, {'name' => 'signup/index.html.erb', 'duration' => 5.0, 'layout' => 'layouts/signup'}]
      entry3.fields['rails_rendered'].should == [
        {"name" => "help/_extra_help.html.erb", "duration" => 0.3},
        {"name" => "help/_invoices_show.html.erb", "duration" => 0.5},
        {"name" => "shared/_flash.html.erb", "duration" => 0.1},
        {"name" => "invoices/_title_actions.html.erb", "duration" => 4.9},
        {"name" => "shared/_ec_status_info.html.erb", "duration" => 0.1},
        {"name" => "invoices/_invoice_item.html.erb", "duration" => 2.8},
        {"name" => "invoices/_invoice.html.erb", "duration" => 19.9},
        {"name" => "invoices/_invoice_content.html.erb", "duration" => 22.1},
        {"name" => "layouts/_head.html.erb", "duration" => 0.1},
        {"name" => "shared/_topnav.html.erb", "duration" => 2.3},
        {"name" => "shared/_nav_my_money.html.erb", "duration" => 4.0},
        {"name" => "shared/_nav_taxes.html.erb", "duration" => 2.2},
        {"name" => "shared/_main_navigation.html.erb", "duration" => 12.3},
        {"name" => "shared/_work_subnav.html.erb", "duration" => 2.1},
        {"name" => "invoices/_subnav.html.erb", "duration" => 2.2},
        {"name" => "invoices/show.html.erb", "layout" => "layouts/application", "duration" => 57.2}
      ]
      entry4.fields['rails_rendered'].should == []
      entry5.fields['rails_rendered'].should == []
      entry6.fields['rails_rendered'].should == [{"name" => "companies/income_data.xml.builder", "duration" => 40.9}]
    end
    it "should parse the status code returned" do
      entry1.fields['rails_status'].should == 200
      entry2.fields['rails_status'].should == 200
      entry3.fields['rails_status'].should == 200
      entry4.fields['rails_status'].should == 302
      entry5.fields['rails_status'].should == 200
      entry6.fields['rails_status'].should == 200
    end
    it "should parse the total duration and breakdown" do
      entry1.fields['rails_duration'].should == {"total" => 12, "views" => 0.9, "activerecord" => 4.7}
      entry2.fields['rails_duration'].should == {"total" => 6, "views" => 5.5, "activerecord" => 0.0}
      entry3.fields['rails_duration'].should == {"total" => 120.7, "views" => 55.2, "activerecord" => 65.5}
      entry4.fields['rails_duration'].should == {"total" => 28}
      entry5.fields['rails_duration'].should == {"total" => 12}
      entry6.fields['rails_duration'].should == {"total" => 133, "views" => 35.3, "activerecord" => 57.0}
    end
    
    it "should parse the subdomain" do
      entry1.fields['rails_subdomain'].should == 'subdomain5'
      entry2.fields['rails_subdomain'].should be_nil
      entry3.fields['rails_subdomain'].should == 'subdomain3'
      entry4.fields['rails_subdomain'].should == 'subdomain2'
      entry5.fields['rails_subdomain'].should == 'subdomain1'
      entry6.fields['rails_subdomain'].should == 'subdomain'
      
    end
    it "should parse the login email" do
      entry1.fields['rails_login'].should be_nil
      entry2.fields['rails_login'].should be_nil
      entry3.fields['rails_login'].should be_nil
      entry4.fields['rails_login'].should == "some@emailhere"
      entry5.fields['rails_login'].should be_nil
      entry6.fields['rails_login'].should be_nil
    end
    it "should parse the session value" do
      entry7.fields['rails_session'].should == "0fcd8dada61aa1327ecdda6ba70352c7"
      entry6.fields['rails_session'].should be_nil
    end

    it "should extract the number of queries" do
      entry7.fields['rails_queries']['total'].should == 9
      entry7.fields['rails_queries']['SELECT'].should == 6
      entry7.fields['rails_queries']['BEGIN'].should == 1
      entry7.fields['rails_queries']['DELETE'].should == 1
      entry7.fields['rails_queries']['COMMIT'].should == 1

      entry6.fields['rails_queries'].should == { "total" => 0 }
    end

    it "should parse flying start event correctly" do
      entry8.fields["flying_start_company_id"].should == "69"
      entry8.fields["flying_start_task_completed"].should == "awesome task"
    end
  end
end

