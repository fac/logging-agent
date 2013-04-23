module LogAgent::Filter

#   ** Alert 1366708323.11720175: - syslog,sshd,invalid_login,authentication_failed,
# 2013 Apr 23 10:12:03 (web1.staging.freeagentcentral.net) any->/var/log/secure
# Rule: 5710 (level 5) -> 'Attempt to login using a non-existent user'
# Src IP: 218.6.224.125
# Apr 23 10:12:03 web1.staging.freeagentcentral.net sshd[11019]: Invalid user ts3 from 218.6.224.125

  class Ossec < Base
    def << event

      if event.message =~ /\*\* Alert ([\d.]+)\:.*\- ([^\s]+)$/
        event.timestamp = Time.at($1.to_f)
        event.fields['ossec_tags'] = $2.split(",")
      end

      if event.message =~ /Rule: (\d+) \(level (\d+)\) -> \'([^\']+)\'$/
        event.fields['ossec_rule_id'] = $1.to_i
        event.fields['ossec_rule_level'] = $2.to_i
        event.fields['ossec_rule_description'] = $3
      end

      if event.message =~ /Src IP: ([\d\.]+)/
        event.fields['ossec_src_ip'] = $1
      end

      if event.message =~ /User: (.+)$/
        event.fields['ossec_username'] = $1
      end

      time = event.timestamp.strftime("%H:%M:%S")
      if event.message =~ /#{time} \(([^\)]+)\)/
        event.fields['ossec_hostname'] = $1
      end
      emit(event)
    end
  end
end