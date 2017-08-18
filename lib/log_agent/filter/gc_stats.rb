module LogAgent::Filter
  class GcStats < Base

    include LogAgent::LogHelper

    def << event
      # parse GC stats line
      # GC stats (23064):1255 (+0) major, 1304 (+0) minor, 10383 allocations,
      # 1808374 (+10383) live slots, 2311088 (+0) total slots, 16076440 (+469608) memory
      # See app/controllers/concerns/memory_instrumentation.rb in the FA app
      # and http://thorstenball.com/blog/2014/03/12/watching-understanding-ruby-2.1-garbage-collector/
      # for a useful description of the values
      if event.message =~ /^GC stats/

        # Defines field order and headings
        gc_field_order = [
          "pid",
          "major_gc_total",
          "major_gc",
          "minor_gc_total",
          "minor_gc",
          "object_allocations",
          "live_slots_total",
          "live_slots",
          "total_slots_total",
          "total_slots",
          "oldmalloc_bytes_total",
          "oldmalloc_bytes",
        ]

        # Pull out the data using a regexp
        data_values = event.message.match(/GC stats \((\d+\)):(\d+) \((.\d+\)) major, (\d+) \((.\d+\)) minor, (\d+) allocations, (\d+) \((.\d+\)) live slots, (\d+) \((.\d+\)) total slots, (\d+) \((.\d+\)) memory/)

        # Turn our array of data, and field names into a hash for ease
        # of use. First element of data_values is the whole matched string so do not
        # include that.
        composed_data = Hash[*gc_field_order.zip(data_values[1..-1]).flatten.compact]

        # Add fields to the event
        composed_data.each do |field,value|
          # Do not add pid, already taken care of else where
          next if field == "pid"
          event.fields[field] = value.to_i
        end
      end

      emit event
    end
  end
end
