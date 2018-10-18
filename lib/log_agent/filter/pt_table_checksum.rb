require 'time'
module LogAgent::Filter
  class PtTableChecksum < Base

    include LogAgent::LogHelper

    def << event
      # 10-10T11:23:55 ...
      if event.message =~ /^(\d{1,2}-\d{1,2}T\d{1,2}:\d{1,2}:\d{1,2})\s+/
        event.timestamp = Time.parse("#{Time.now.year}-#{$1} UTC")
      end

      # 10-17T13:17:54      0      0        0       1       1   0.003 mysql.columns_priv
      if event.message =~ /^([\dT:-]+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s+([\d\.]+)\s+([\w\.]+)$/
        event.fields['errors']       = $2.to_i
        event.fields['diffs']        = $3.to_i
        event.fields['rows']         = $4.to_i
        event.fields['chunks']       = $5.to_i
        event.fields['skipped']      = $6.to_i
        event.fields['time_elapsed'] = $7
        event.fields['table']        = $8
      end

      # 10-10T11:23:55 Skipping table my_database.my_table because ...
      if event.message =~ /skipping/i
        event.fields['skipped'] = true
      end

      # 10-17T00:31:09 Skipping chunk 14 of my_database.my_table because ...
      if event.message =~ /skipping(?: table| chunk \d+ of)? ([\w\.]+)/i
        event.fields['table'] = $1
      end

      # Checksumming my_database.my_table:  39% 00:45 remain
      if event.message =~ /^Checksumming ([\w\.]+):/
        event.fields['table'] = $1
      end

      emit event
    end
  end
end
