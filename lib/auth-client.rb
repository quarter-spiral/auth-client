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
      @venue_token_url = File.join(url, 'api/v1/token/venue')
      @venue_identities_url = File.join(url, 'api/v1/users/batch/identities')
      @attach_venue_identity_url = File.join(url, 'api/v1/users/%s/identities')

      @uuids_batch_url = File.join(url, 'api/v1/uuids/batch')
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

    def venue_token(app_token, venue, venue_data)
      response = @adapter.request(:post, "#{@venue_token_url}/#{venue}", JSON.dump(venue_data), headers: {'Authorization' => "Bearer #{app_token}"})

      case response.status
      when 403
        raise "Forbidden"
      when 201
        JSON.parse(response.body.first)['token']
       else
         raise "Couldn't create venue token!"
      end
    end

    def venue_identities_of(token, *uuids)
      response = @adapter.request(:get, @venue_identities_url, JSON.dump(uuids), headers: {'Authorization' => "Bearer #{token}"})
      case response.status
      when 403
        raise "Forbidden"
      when 404
        raise Service::Client::ServiceError.new("One of the venue ids not found: #{uuids}")
      when 200
        data = JSON.parse(response.body.first)
        data = Hash[data.map {|k,v| [k, v['venues']]}]

        data.size == 1 ? data.values.first : data
      else
        raise "Error retrieving the venue identities of #{uuids}"
      end
    end

    def attach_venue_identity_to(token, uuid, venue, venue_identity)
      url = @attach_venue_identity_url % uuid
      response = @adapter.request(:post, url, JSON.dump(venue => venue_identity), headers: {"Authorization" => "Bearer #{token}"})
      case response.status
      when 422
        error = JSON.parse(response.body.first)['error']
        raise Service::Client::ServiceError.new(error)
      when 201
        true
      else
        raise "Unexpected error while attaching venue ids"
      end
    end

    def uuids_of(token, venue_params)
      response = @adapter.request(:post, @uuids_batch_url, JSON.dump(venue_params), headers: {'Authorization' => "Bearer #{token}"})
      case response.status
      when 403
        raise "Forbidden"
      when 200
        JSON.parse(response.body.first)
      else
        raise "Error retrieving the uuids!"
      end
    end
  end
end
