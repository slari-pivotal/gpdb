require 'xmlrpc/client'
require 'uri'

# http://confluence.zutubi.com/display/pulse0206/Remote+API+Reference
class PulseProxy
  def initialize(url, username, password)
    @url = url
    @username = username
    @password = password
  end

  def refresh
    @token = nil
  end

  def request_triggerBuild(project_name, trigger_options)
    #triggerBuild returns an array of request IDs (strings),
    #but only if we pass trigger_options
    retry_call { proxy.triggerBuild(token, project_name, trigger_options) }
  end

  def request_waitForBuildRequestToBeActivated(request_id, timeoutMillis)
    retry_call { proxy.waitForBuildRequestToBeActivated(token, request_id, timeoutMillis) }
  end

  def request_getBuildRequestStatus(request_id)
    retry_call { proxy.getBuildRequestStatus(token, request_id) }
  end

  def request_getBuild(project_name, build_id)
    retry_call { proxy.getBuild(token, project_name, build_id) }
  end

  def request_getMessagesInBuild(project_name, build_id)
    retry_call { proxy.getMessagesInBuild(token, project_name, build_id) }
  end

  def request_getArtifactsInBuild(project_name, build_id)
    retry_call { proxy.getArtifactsInBuild(token, project_name, build_id) }
  end

  # The token will be retrieved one time for this Pulse API connection and
  # reused throughout API calls.
  # Note that the token is only valid for 30 minutes.
  def token
    @token ||= retry_call { proxy.login(@username, @password) }
  end

  def proxy
    @proxy ||= server.proxy('RemoteApi')
  end

  def server
    @server ||= XMLRPC::Client.new2("#{@url}/xmlrpc")
  end

  def retry_call(&block)
    attempts = 0
    begin
      yield
    rescue SocketError => error
      raise error if attempts > 3
      puts "Got a socket error #{error} - retry ##{attempts}"
      sleep 10
      attempts += 1
      retry
    end
  end
end
