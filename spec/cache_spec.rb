require_relative './spec_helper'

require 'cache-client'
require 'cache/backend/inmemory'

require 'timecop'

def change_name(new_name)
  cookie = AUTH_HELPERS.login(@user['name'], @user['password'])
  AUTH_HELPERS.client.put "/profile", {"Cookie" => cookie}, {"user[name]" => new_name}
end

describe Auth::Client do
  before do
    AUTH_HELPERS.delete_existing_users!
    @user = AUTH_HELPERS.create_user!
    @old_user_name = @user['name']
    @new_user_name = @old_user_name.reverse
    @token = AUTH_HELPERS.get_token
  end

  describe "without caching" do
    before do
      @client = Auth::Client.new('http://auth-backend.dev', adapter: [:rack, AUTH_APP])
    end

    it "does not cache the token owner" do
      @client.token_owner(@token)['name'].must_equal @old_user_name
      change_name(@new_user_name)
      @client.token_owner(@token)['name'].must_equal @new_user_name
    end

    it "does not cache the token validity" do
      @client.token_valid?(@token).must_equal true
      AUTH_HELPERS.delete_existing_users!
      @client.token_valid?(@token).must_equal false
    end

    it "does not cache venue identities" do
      @client.venue_identities_of(@token, @user['uuid']).must_equal({})
      @client.attach_venue_identity_to(@token, @user['uuid'], 'facebook', {'venue-id' => "123", "name" => "Test"})
      @client.venue_identities_of(@token, @user['uuid']).must_equal("facebook" => {'id' => "123", "name" => "Test"})
    end
  end

  describe "caching" do
    before do
      @cache = Cache::Client.new(Cache::Backend::Inmemory)
      @client = Auth::Client.new('http://auth-backend.dev', adapter: [:rack, AUTH_APP], cache: @cache)
    end

    it "caches the token owner" do
      @client.token_owner(@token)['name'].must_equal @old_user_name
      change_name(@new_user_name)
      @client.token_owner(@token)['name'].must_equal @old_user_name
    end

    it "expires the town owner cache after 5 minutes by default" do
      now = Time.now
      @client.token_owner(@token)['name'].must_equal @old_user_name
      change_name(@new_user_name)
      @client.token_owner(@token)['name'].must_equal @old_user_name

      # expires after 10:00 minutes at most
      Timecop.freeze(now + (10 * 60)) do
        @client.token_owner(@token)['name'].must_equal @new_user_name
      end
    end

    it "does not cache the token validity" do
      @client.token_valid?(@token).must_equal true
      AUTH_HELPERS.delete_existing_users!
      @client.token_valid?(@token).must_equal false
    end

    it "does not cache venue identities" do
      @client.venue_identities_of(@token, @user['uuid']).must_equal({})
      @client.attach_venue_identity_to(@token, @user['uuid'], 'facebook', {'venue-id' => "123", "name" => "Test"})
      @client.venue_identities_of(@token, @user['uuid']).must_equal("facebook" => {'id' => "123", "name" => "Test"})
    end
  end
end