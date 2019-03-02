#!/usr/bin/env ruby

@requests = Array.new()
Line = Struct.new(:date,:time, :request, :responceCode)

#date, time, request,responseCode
LOG_FORMAT = /\[([0-9]+\/[A-z]+\/[0-9]+):(.*)\s\+[0-9]+\]\s"(.*)"\s([0-9]+)/


def parse_raw_line(line)
#  puts line
  line.match(LOG_FORMAT) { |m|

        request = Line.new(*m.captures)
        replaced = replaceQueryParameters(request.request)
        time=removeSeconds(request.time)

        if not replaced.nil? and not time.nil?
          request.request=replaced
          request.time = time
        end

        @requests<<request
  }

end

def replaceQueryParameters(str)

  requestPattern = /(.*Dispatch\/)[0-9]+(\/[A-z]+\?).*/
  replaceRule = '\1path\2xxx'

  str.sub(requestPattern, replaceRule)

end


#01:00:24
def removeSeconds(str)

  str.sub(/([0-9]+:[0-9]+:)[0-9]+/,'\100')
end

def groupByTime(struct)

  struct.group_by(&:time).map do |date, time, request, responceCode|
    [time, request]
  end

end

def groupByRequest(array)

  workload=[]

  array.each { |t|
    grouped=[]
    t[0].group_by(&:request).map  do  | request, requests|

      grouped <<[ requests[0].time, request, requests.count]

    end

    workload<<[t[0].count,grouped]

    }

  workload

end

def calculatePercentage(current,total)
    ((current/total.to_f)*100).ceil(2)
end


#opens file and feeds it to a function that runs RegExp from LOG_FORMAT against each line
file='./InputData/access_log_short'
File.readlines(file).each do |line|
  parse_raw_line(line)
end

test = groupByTime(@requests)

@requests = []

final = groupByRequest(test)

# final.each {
#     | transaction|
#        transaction[1].each { |hits|
#       puts hits[0]+',total_hits = '+hits[2].to_s+', percentage = '+calculate_percentage(hits[2],transaction[0]).to_s+'%,"'+hits[1]+'"'
# }
# }

max_tpmHash = Hash.new()

final.each{ |transaction|

  transaction[1].each {|hits|

    if not max_tpmHash.empty?
      if not max_tpmHash[hits[1]].nil?
        if (max_tpmHash[hits[1]]<hits[2])
          max_tpmHash.store(hits[1],hits[2])
        end
      else
        max_tpmHash.store(hits[1],hits[2])
      end
    else
      max_tpmHash[hits[1]]=hits[2]
    end

  }
  max_tpmHash
}

total_hits = Hash.new()

final.each{ |transaction|

  transaction[1].each {|hits|

    if not total_hits.empty?
      if not total_hits[hits[1]].nil?

        total_hits.store(hits[1],total_hits[hits[1]]+hits[2])

      else
        total_hits.store(hits[1],hits[2])
      end
    else
      total_hits.store(hits[1],hits[2])
    end

  }
  total_hits
}

#Print results
 total=0
 max_tpmHash.each_value {|value |  total=total+value}
 puts 'max_tpm_all_transactions = '+total.to_s

 max_tpmHash.each {|key, value |

   if not total_hits[key].nil?
     puts 'total_hits = '+total_hits[key].to_s+', percentage = ' + calculatePercentage(value,total).to_s+'%, max_tpm='+value.to_s+' '+key
   end

 }

