# coding: utf-8
require 'spec_helper'

def log_fixture(name)
  LogAgent::Event.new({
    :message => File.read(File.expand_path("../../../data/rails_entries/#{name}.log", __FILE__))
  })
end

describe LogAgent::Filter::Rails do
  let(:sink) { mock("MySinkObject", :<< => nil) }
  let(:filter) { LogAgent::Filter::Rails.new sink }
  
  it "should be created with new <sink>" do
    filter.sink.should == [sink]
  end

  describe "parsing" do
    let(:entry1) { log_fixture('entry1').tap { |e| filter << e } }
    let(:entry2) { log_fixture('entry2').tap { |e| filter << e } }
    let(:entry3) { log_fixture('entry3').tap { |e| filter << e } }
    let(:entry4) { log_fixture('entry4').tap { |e| filter << e } }
    let(:entry5) { log_fixture('entry5').tap { |e| filter << e } }
    let(:entry6) { log_fixture('entry6').tap { |e| filter << e } }
                      
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

    it "should use the current time if log timestamp is invalid" do
      entry5.timestamp.should be_within(1).of(Time.now)
    end

    it "should use the current time if log timestamp is absent" do
      entry6.timestamp.should be_within(1).of(Time.now)
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
      entry3.fields['rails_duration'].should == {"total" => 78, "views" => 55.2, "activerecord" => 65.5}
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
  end
end

