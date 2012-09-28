require_relative './spec_helper'

ENV['QS_AUTH_BACKEND_URL'] = 'http://auth-backend.dev'
AUTH_APP = Auth::Backend::App.new(test: true)

require 'auth-backend/test_helpers'
auth_helpers = Auth::Backend::TestHelpers.new(AUTH_APP)
token = auth_helpers.get_token

describe Auth::Client do
  before do
    @client = Auth::Client.new(adapter: [:rack, AUTH_APP])
  end

  it "knows that an invalid token is invalid" do
    @client.token_valid?(token.reverse).must_equal false
  end

  it "knows that a valid token is valid" do
    @client.token_valid?(token).must_equal true
  end
end
