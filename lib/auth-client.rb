require 'service-client'
require "auth-client/version"

module Auth
  class Client
    def initialize(url, options = {})
      @adapter = Service::Client::Adapter::Faraday.new(options)

      @token_url = File.join(url, 'api/v1/verify')
      @token_owner_url = File.join(url, 'api/v1/me')
    end

    def token_valid?(token)
      response = @adapter.request(:get, @token_url, '', headers: {'Authorization' => "Bearer #{token}"})
      response.status == 200
    end

    def token_owner(token)
      response = @adapter.request(:get, @token_owner_url, '', headers: {'Authorization' => "Bearer #{token}"})
      response.status == 200 ? JSON.parse(response.body.first) : nil
    end
  end
end
