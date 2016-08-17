require 'xmlrpc/client'
require 'uri'

class PulseProject
  attr_accessor :url
  attr_accessor :project_name

  def initialize(url, project_name)
    self.url = url
    self.project_name = project_name
  end

  def checkman_json
    {
        'result' => (current_build_completed? ? latest_build['succeeded'] : previous_build['succeeded']),
        'changing' => started? && !current_build_completed?,
        'url' => (build_id.nil? ? base_url : build_url),
        'info' => info,
    }
  end

  private

  def info
    if started?
      [
          ["Build", build_id],
          ["Duration", (current_build_completed? ? build_duration : "N/A")],
          ["Started", latest_build['startTime'] && latest_build['startTime'].to_time ? latest_build['startTime'].to_time.strftime("%I:%M%p %m/%d/%Y %Z") : "N/A"],
          ["Progress", (latest_build['progress'] == -1 ? "N/A" : "#{latest_build['progress']}%")],
          ["Revision", latest_build['revision']],
          ["Owner", "#{latest_build['owner']}#{latest_build['personal'] ? " (Personal)" : ""}"],
          ["Errors", (latest_build['errorCount'] == -1 ? "N/A" : latest_build['errorCount'])],
          ["Warnings", (latest_build['warningCount'] == -1 ? "N/A" : latest_build['warningCount'])],
      ] + test_info
    else
      [
          ["Build", "not yet started"],
      ]
    end
  end

  def started?
    latest_build.any?
  end

  def current_build_completed?
    latest_build['completed']
  end

  def previous_build
    latest_builds[1] || {}
  end


  def latest_build
    latest_builds[0] || {}
  end

  def latest_builds
    @latest_builds ||= Proxy.new(url).latest_builds_for_project(project_name)
  end

  def base_url
    URI.parse(url + URI.escape("/browse/projects/#{project_name}")).to_s
  end

  def build_url
    "#{base_url}/builds/#{build_id}/"
  end

  def build_id
    latest_build['id']
  end

  def build_duration
    seconds = (latest_build['endTimeMillis'].to_i - latest_build['startTimeMillis'].to_i) / 1000
    Time.at(seconds).utc.strftime("%H:%M:%S")
  end

  def test_info
    if latest_build['tests']
      [["-", ""], ["Tests", ""]] + test_summary
    else
      []
    end
  end

  def test_summary
    [
      [" - Total", latest_build['tests']['total']],
      [" - Errors", latest_build['tests']['errors']],
      [" - Expected Failures", latest_build['tests']['expectedFailures']],
      [" - Failures", latest_build['tests']['failures']],
      [" - Passed", latest_build['tests']['passed']],
      [" - Skipped", latest_build['tests']['skipped']]
    ]
  end

  class Proxy
    attr_accessor :url

    def initialize(url)
      self.url = url
    end

    def latest_builds_for_project(project_name)
      @latest_builds_for_project ||= {}
      @latest_builds_for_project[project_name] ||= proxy.getLatestBuildsForProject(token, project_name, false, 2)
    end

    def token
      @token ||= proxy.login(username, password)
    end

    USERNAME_ENV = 'PULSE_CHECKMAN_USERNAME'
    PASSWORD_ENV = 'PULSE_CHECKMAN_PASSWORD'

    def username
      @username ||= ENV[USERNAME_ENV] ||
                    raise("Missing environment variable #{USERNAME_ENV}")
    end

    def password
      @password ||= ENV[PASSWORD_ENV] ||
                    raise("Missing environment variable #{PASSWORD_ENV}")
    end

    def proxy
      @proxy ||= server.proxy('RemoteApi')
    end

    def server
      @server ||= XMLRPC::Client.new2("#{url}/xmlrpc")
    end
  end
end
