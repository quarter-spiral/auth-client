require 'service-client'
require "auth-client/version"

module Auth
  class Client
    def initialize(options = {})
      @adapter = Service::Client::Adapter::Faraday.new(options)

      @token_url = File.join(ENV['QS_AUTH_BACKEND_URL'], 'api/v1/verify')
    end

    def token_valid?(token)
      response = @adapter.request(:get, @token_url, '', headers: {'Authorization' => "Bearer #{token}"})
      response.status == 200
    end
  end
end
