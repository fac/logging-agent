require 'time'
module LogAgent::Filter
  class PtDeadlock < Base

    include LogAgent::LogHelper

    def << event
      lines = event.message.split("\n")
      lines.shift


      lines.each_index do |i|
        tx = lines[i].split(/ /, 16)

        # Timestamps are always the same for each tx
        event.timestamp = event.timestamp = Time.parse(tx[1])

        event.fields["tx#{i+1}"] = {}
        event.fields["tx#{i+1}"]['server']    = tx[0]
        event.fields["tx#{i+1}"]['thread']    = tx[2].to_i
        event.fields["tx#{i+1}"]['txn_id']    = tx[3].to_i
        event.fields["tx#{i+1}"]['txn_time']  = tx[4].to_i
        event.fields["tx#{i+1}"]['user']      = tx[5]
        event.fields["tx#{i+1}"]['hostname']  = tx[6]
        event.fields["tx#{i+1}"]['ip']        = tx[7]
        event.fields["tx#{i+1}"]['db']        = tx[8]
        event.fields["tx#{i+1}"]['tbl']       = tx[9]
        event.fields["tx#{i+1}"]['idx']       = tx[10]
        event.fields["tx#{i+1}"]['lock_type'] = tx[11]
        event.fields["tx#{i+1}"]['lock_mode'] = tx[12]
        event.fields["tx#{i+1}"]['wait_hold'] = tx[13]
        event.fields["tx#{i+1}"]['victim']    = tx[14].to_i
        event.fields["tx#{i+1}"]['query']     = tx[15]
      end

      emit event
    end
  end
end
