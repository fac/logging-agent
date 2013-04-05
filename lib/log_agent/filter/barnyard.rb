require 'time'
module LogAgent::Filter
  class Barnyard < Base

    include LogAgent::LogHelper

    def << event
      if event.message =~ /^([0-9\-:\.\/]+)  \[\*\*\] \[([0-9]+):([0-9]+):([0-9]+)\] (.*) \[\*\*\] \[Classification(| ID): (.*)\] \[Priority(| ID): (.*?)\] {(.*?)} ([0-9\.:]+) -> ([0-9\.:]+)$/
        event.timestamp = Time.parse("#{$1} UTC") rescue Time.now
        event.fields['barnyard_gen_id']    = $2.to_i
        event.fields['barnyard_sig_id']    = $3.to_i
        event.fields['barnyard_sig_rev']   = $4.to_i
        event.fields['barnyard_desc']      = $5
        event.fields['barnyard_class']     = $7
        event.fields['barnyard_priority']  = $9.to_i
        event.fields['barnyard_proto']     = $10
        event.fields['barnyard_src_ip']    = $11.split(':')[0]
        event.fields['barnyard_src_port']  = $11.split(':')[1] ? $11.split(':')[1].to_i : nil
        event.fields['barnyard_dest_ip']   = $12.split(':')[0]
        event.fields['barnyard_dest_port'] = $12.split(':')[1] ? $12.split(':')[1].to_i : nil

      elsif event.message =~ /^([0-9\-:\.\/]+)  \[\*\*\] \[([0-9]+):([0-9]+):([0-9]+)\] (.*) \[\*\*\] $/
        event.timestamp = Time.parse("#{$1} UTC") rescue Time.now
        event.fields['barnyard_gen_id']  = $2.to_i
        event.fields['barnyard_sig_id']  = $3.to_i
        event.fields['barnyard_sig_rev'] = $4.to_i
        event.fields['barnyard_desc']    = $5
      end

      emit event
    end
  end
end
