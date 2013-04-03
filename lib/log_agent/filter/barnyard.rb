module LogAgent::Filter
  class Barnyard < Base

    include LogAgent::LogHelper

    def << event
      if event.message =~ /^[0-9\-:\.\/]+  \[\*\*\] \[([0-9]+):([0-9]+):([0-9]+)\] (.*) \[\*\*\] \[Classification(| ID): (.*)\] \[Priority(| ID): (.*?)\] {(.*?)} ([0-9\.:]+) -> ([0-9\.:]+)$/
        event.fields['barnyard_gen_id']    = $1.to_i
        event.fields['barnyard_sig_id']    = $2.to_i
        event.fields['barnyard_sig_rev']   = $3.to_i
        event.fields['barnyard_desc']      = $4
        event.fields['barnyard_class']     = $6
        event.fields['barnyard_priority']  = $8.to_i
        event.fields['barnyard_proto']     = $9
        event.fields['barnyard_src_ip']    = $10.split(':')[0]
        event.fields['barnyard_src_port']  = $10.split(':')[1] ? $10.split(':')[1].to_i : nil
        event.fields['barnyard_dest_ip']   = $11.split(':')[0]
        event.fields['barnyard_dest_port'] = $11.split(':')[1] ? $11.split(':')[1].to_i : nil

      elsif event.message =~ /^[0-9\-:\.\/]+  \[\*\*\] \[([0-9]+):([0-9]+):([0-9]+)\] (.*) \[\*\*\] $/
        event.fields['barnyard_gen_id']  = $1.to_i
        event.fields['barnyard_sig_id']  = $2.to_i
        event.fields['barnyard_sig_rev'] = $3.to_i
        event.fields['barnyard_desc']    = $4
      end

      emit event
    end
  end
end
