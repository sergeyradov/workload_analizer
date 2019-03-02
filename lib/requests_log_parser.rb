class RequestsLogParser

  @requests = nil

  Line = Struct.new(:date,:time, :request, :responce_code)


  public

  def initialize

    @requests = []

  end

  def getRequests(raw_file_path,regExpForLine)

    if File.exist?((raw_file_path)) && !regExpForLine.nil?

      File.readlines(raw_file_path).each do |line|

        line = parseRawLine(line,regExpForLine)

        next if line.nil?

        request_filter = /(GET|POST|PUT|DELETE|PATCH).*\sHTTP/
        extension_filter = /\.jpg|\.png|\.txt|\.ico|\.log|\.css|\.js|\.gif|.xml/
        path_filter = /apache-log|administrator|LICENSE/
        response_code_filter = /404|500/

        request = line[:request].to_s[request_filter]
        resource = request.to_s[extension_filter]

        @requests << line if resource.nil? && line[:responce_code][response_code_filter].nil? && line[:request][path_filter].nil?
      end

      @requests

    else

      raise raw_file_path+' was not found'

    end


  end

  private

  def parseRawLine(rawLogLine,regExpForLine)


    rawLogLine.match(regExpForLine) { |m|

      request = Line.new(*m.captures)
      replaced = replaceQueryParameters(request.request)
      time=removeSeconds(request.time)

      if !replaced.nil? && !time.nil?
        request.request=replaced
        request.time = time
      end

      request

    }

  end

  # I don't like the idea to keep following line in place hardcoded.
  #in addition it ignore a few strings that don't have parameters, but I don't fully understand how it works.

  def replaceQueryParameters(requestString)

    requestPattern = /(.*Dispatch\/)[0-9]+(\/[A-z]+\?).*/
    replaceRule = '\1id\2xxx'

    requestString.sub(requestPattern, replaceRule)

  end

  def removeSeconds(requestTime)

    requestTime.sub(/([0-9]+:[0-9]+:)[0-9]+/,'\100')

  end

end

