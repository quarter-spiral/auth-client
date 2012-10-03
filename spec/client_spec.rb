require_relative './spec_helper'

AUTH_APP = Auth::Backend::App.new(test: true)

require 'auth-backend/test_helpers'
auth_helpers = Auth::Backend::TestHelpers.new(AUTH_APP)
token = auth_helpers.get_token
user = auth_helpers.user_data

at_exit do
  auth_helpers.cleanup!
end

describe Auth::Client do
  before do
    @client = Auth::Client.new('http://auth-backend.dev', adapter: [:rack, AUTH_APP])
  end

  it "knows that an invalid token is invalid" do
    @client.token_valid?(token.reverse).must_equal false
  end

  it "knows that a valid token is valid" do
    @client.token_valid?(token).must_equal true
  end

  it "returns nil as the token owner for an invalid token" do
    @client.token_owner(token.reverse).must_be_nil
  end

  it "returns information about the token owner for a valid token" do
    @client.token_owner(token).must_equal('uuid' => user['uuid'], 'name' => user['name'], 'email' => user['email'])
  end
end
