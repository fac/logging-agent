module LogAgent::Filter
  class Rails < Base
    
    include LogAgent::LogHelper
    
    def << event
      if event.message =~ /^Started ([^\s]+) \"([^\"]+)\" for (\d+\.\d+\.\d+\.\d+)/
        event.fields['rails_method'] = $1
        event.fields['rails_request_path'] = $2
        event.fields['rails_remote_addr'] = $3 
      end

      if event.message =~ /^Started .* for .* at (\d+-\d+-\d+ \d+:\d+:\d+ \+\d+)/
        event.timestamp = Time.parse($1) rescue Time.now
      end

      if event.message =~ /Processing by ([^#]+)#([^\s]+) as ([^\s]*)/
        event.fields['rails_controller'] = $1
        event.fields['rails_action'] = $2
        event.fields['rails_format'] = $3 == '' ? nil : $3
      end

      if event.message =~ /^Redirected to (.*)$/
        event.fields['rails_redirect'] = $1
      end

      if event.message =~ /^Completed (\d+) .* in (\d+)ms/
        event.fields['rails_status'] = $1.to_i
        event.fields['rails_duration'] = {'total' => $2.to_f}
      end

      if event.message =~ /^Completed .*Views: ([\d.]+)ms/
        event.fields['rails_duration'] ||= {}
        event.fields['rails_duration']['views'] = $1.to_f
      end

      if event.message =~ /^Completed .*ActiveRecord: ([\d.]+)ms/
        event.fields['rails_duration'] ||= {}
        event.fields['rails_duration']['activerecord'] = $1.to_f
      end

      if event.message =~ /subdomain \[([^\[]+)\]$/
        event.fields['rails_subdomain'] = $1
      end

      if event.message =~ /Logged in as (.*)$/
        event.fields['rails_login'] = $1
      end
      
      event.fields['rails_rendered'] = []
      event.message.scan(/Rendered (.+?) (?:within (.*) )?\(([\d.]+)ms\)/) do |match|
        template = {"name" => match[0], "duration" => match[2].to_f}
        template['layout'] = match[1] if match[1]
        event.fields['rails_rendered'] << template
      end

      emit event
    end
    
  end
end
