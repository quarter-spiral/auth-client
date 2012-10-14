require 'service-client'
require 'auth-client/version'
require 'base64'

module Auth
  class Client
    def initialize(url, options = {})
      @adapter = Service::Client::Adapter::Faraday.new(options)

      @token_url = File.join(url, 'api/v1/verify')
      @token_owner_url = File.join(url, 'api/v1/me')
      @app_token_url = File.join(url, 'api/v1/token/app')
    end

    def token_valid?(token)
      response = @adapter.request(:get, @token_url, '', headers: {'Authorization' => "Bearer #{token}"})
      response.status == 200
    end

    def token_owner(token)
      response = @adapter.request(:get, @token_owner_url, '', headers: {'Authorization' => "Bearer #{token}"})
      response.status == 200 ? JSON.parse(response.body.first) : nil
    end

    def create_app_token(app_id, app_secret)
      auth_string = Base64.encode64("#{app_id}:#{app_secret}").gsub("\n",'')

      headers = {'Authorization' => "Basic #{auth_string}"}
      response = @adapter.request(:post, @app_token_url, '', headers: headers)

      raise "Invalid app data" unless response.status == 201
      JSON.parse(response.body.first)['token']
    end
  end
end
