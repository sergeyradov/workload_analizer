class WorkloadParser

  @requests = nil
  @max_tpm_hash= nil
  @total_hits_hash = nil
  ResultSet = Struct.new(:total_hits,:percentage, :max_tpm, :request)

  public

  def initialize(parsed_requests)

    # expected Line[] as Struct.new(:date,:time, :request, :responce_code)[]
    @requests = parsed_requests
    @max_tpm_hash = {}
    @total_hits_hash = {}

  end

  def get_workload

    calculate_workload

    result = []
    # Print results to console
    max_tpm_all_transactions = 0

    @max_tpm_hash.each_value { |value|  max_tpm_all_transactions += value }

    result << 'max_tpm_all_transactions = ' + max_tpm_all_transactions.to_s

    total_hits_sum = 0
    @total_hits_hash.each_value { |value| total_hits_sum += value }

    @max_tpm_hash.each { |key, value|

      next unless !@total_hits_hash[key].nil? && !@total_hits_hash.nil?

      result << 'total_hits = '+@total_hits_hash[key].to_s+', percentage = ' + calculate_percentage(@total_hits_hash[key], total_hits_sum).to_s+'%, max_tpm='+value.to_s+' '+key

    }

    @max_tpm_hash = nil
    # noinspection RubyClassVariableUsageInspection
    @@total_hits_hash = nil
    @requests=nil
   result

  end

  private

  def calculate_workload

    grouped_by_time_requests = group_by_time(@requests)
    grouped_by_requests = group_by_request(grouped_by_time_requests)

    get_max_tpms grouped_by_requests
    get_total_hits grouped_by_requests

  end

  def get_max_tpms(grouped_by_requests)

    grouped_by_requests.each{ |transaction|

      transaction[1].each { |hits|

        if !@max_tpm_hash.empty?
          if !@max_tpm_hash[hits[1]].nil?
            @max_tpm_hash.store(hits[1], hits[2]) if @max_tpm_hash[hits[1]]<hits[2]
          else
            @max_tpm_hash.store(hits[1], hits[2])
          end
        else
          @max_tpm_hash.store(hits[1], hits[2])
        end

      }

      @max_tpm_hash
    }

  end

  def get_total_hits(grouped_by_requests)
    # total_hits = Hash.new()
    grouped_by_requests.each{ |transaction|

      transaction[1].each { |hits|

        if !@total_hits_hash.empty?
          if !@total_hits_hash[hits[1]].nil?

            @total_hits_hash.store(hits[1], @total_hits_hash[hits[1]]+hits[2])

          else
            @total_hits_hash.store(hits[1], hits[2])
          end
        else
          @total_hits_hash.store(hits[1], hits[2])
        end

      }
      @total_hits_hash = @total_hits_hash.sort_by{ |k, v| v }.reverse.to_h
    }

  end

  def group_by_time(array_of_lines)

    grouped_by_time_requests = []

    array_of_lines.group_by(&:time).map do |date, time, request, responceCode|

      grouped_by_time_requests << [time, request]

    end

    grouped_by_time_requests

  end

  def group_by_request(grouped_requests_by_time)

    workload = []

    grouped_requests_by_time.each { |time_ranged_requests|
      grouped = []

      time_ranged_requests[0].group_by(&:request).map do |request, requests|

        grouped << [requests[0].time, request, requests.count]

      end

      workload << [time_ranged_requests[0].count, grouped]

    }

    workload

  end

  def calculate_percentage(transactions_hits, total_hits)

    ((transactions_hits / total_hits.to_f) * 100).ceil

  end

end