#!/usr/bin/env ruby

require_relative './lib/requests_log_parser'
require_relative './lib/workload_parser'

class Main

  @parser=nil
  @requests = nil

  def main(accessLogFile, accessLogLineRegExp)

    resultSet = nil

    if File.exists?(accessLogFile)

      parser = RequestsLogParser.new

      @requests = parser.getRequests(accessLogFile ,accessLogLineRegExp)
      parser = nil

      workloadParser = WorkloadParser.new(@requests)
      @requests=nil

      resultSet = workloadParser.get_workload
      workloadParser = nil

      unless resultSet.nil?
        $i = 0
        $num = resultSet.count
        $num = resultSet.count > 31 ? 30 : resultSet.count

        until $i >= $num do
          puts resultSet[$i].to_s
          $i += 1;
        end

        # Uncomment if all transactions should appear.
        # resultSet.each {|line| puts line.to_s}

      end

    end

  end

end

# Execution

log_file_path = './InputData/access_log_short'
log_line_reg_exp = /\[([0-9]+\/[A-z]+\/[0-9]+):(.*)\s\+[0-9]+\]\s"(.*)"\s([0-9]+)/
# requestPattern =  /(.*Dispatch\/)[0-9]+(\/[A-z]+\?).*/

executor = Main.new
executor.main(log_file_path, log_line_reg_exp)

