require 'xmlrpc/client'
require 'uri'

# http://confluence.zutubi.com/display/pulse0206/Remote+API+Reference
class PulseProxy
  def initialize(url, username, password)
    @url = url
    @username = username
    @password = password
  end

  def request_triggerBuild(project_name, trigger_options)
    #triggerBuild returns an array of request IDs (strings),
    #but only if we pass trigger_options
    proxy.triggerBuild(token, project_name, trigger_options)
  end

  def request_waitForBuildRequestToBeActivated(request_id, timeoutMillis)
    proxy.waitForBuildRequestToBeActivated(token, request_id, timeoutMillis)
  end

  def request_getBuildRequestStatus(request_id)
    proxy.getBuildRequestStatus(token, request_id)
  end

  def request_getBuild(project_name, build_id)
    proxy.getBuild(token, project_name, build_id)
  end

  def request_getMessagesInBuild(project_name, build_id)
    proxy.getMessagesInBuild(token, project_name, build_id)
  end

  # The token will be retrieved one time for this Pulse API connection and
  # reused throughout API calls.
  # Note that the token is only valid for 30 minutes.
  def token
    @token ||= proxy.login(@username, @password)
  end

  def proxy
    @proxy ||= server.proxy('RemoteApi')
  end

  def server
    @server ||= XMLRPC::Client.new2("#{@url}/xmlrpc")
  end
end
