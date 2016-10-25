require "net/http"
require "uri"

class PulseBuildResult

  def initialize(pulse_options, build_result, build_messages, build_artifacts)
    @pulse_options = pulse_options
    @build_result = build_result
    @build_messages = build_messages
    @build_artifacts = build_artifacts
  end

  def build_successful?
    @build_result['succeeded']
  end

  def print_build_stats
    puts "Build ID fetched from pulse: #{@build_result['id']}"

    puts "Build " + (build_successful? ? "succeeded" : "failed")
    puts "Revision: #{@build_result['revision']}"
    puts "   Owner: #{@build_result['owner']}"
    puts "  Errors: #{@build_result['errorCount']}"
    puts "Warnings: #{@build_result['warningCount']}"

    seconds = (@build_result['endTimeMillis'].to_i - @build_result['startTimeMillis'].to_i) / 1000
    puts "Duration: " + (@build_result['completed'] ? Time.at(seconds).utc.strftime("%H:%M:%S") : "N/A")

    puts "=== Messages ==="
    @build_messages.each do |message|
      puts "  #{message}"
    end
  end

  def print_build_artifacts
    puts "\n=== Artifacts ===\n"
    @build_artifacts.each do |artifact|
      artifact_name = artifact["name"]
      next unless artifact_name =~ /\.log/

      # convert "Test Results (results.log) into 'results.log'"
      artifact_name.gsub!(/.*\((.*)\)/) { |match| "#{$1}" }
      uri_string = [@pulse_options.url, artifact["permalink"], URI.escape(artifact_name)].join("")
      puts "\n= #{artifact_name} @ #{uri_string} =\n"
      response = fetch_uri(uri_string)
      puts response.body
    end
  end

  def fetch_uri(uri_string, limit = 10)
    raise ArgumentError, 'HTTP redirect too deep' if limit == 0
    response = Net::HTTP.get_response(URI.parse(uri_string))
    case response
    when Net::HTTPSuccess     then response
    when Net::HTTPRedirection then fetch_uri(response['location'], limit - 1)
    else
      response.error!
    end
  end
end
