require_relative './spec_helper'

module Graph::Backend
  class Connection
    alias raw_initialize initialize
    def initialize(*args)
      raw_initialize(*args)
      @auth = AUTH_CLIENT
    end
  end
end

require 'auth-backend/test_helpers'
auth_helpers = Auth::Backend::TestHelpers.new(AUTH_APP)

at_exit do
  auth_helpers.cleanup!
end

describe Auth::Client do
  before do
    @client = AUTH_CLIENT
    auth_helpers.delete_existing_users!
    @user = auth_helpers.create_user!
    @token = auth_helpers.get_token
  end

  it "knows that an invalid token is invalid" do
    @client.token_valid?(@token.reverse).must_equal false
  end

  it "knows that a valid token is valid" do
    @client.token_valid?(@token).must_equal true
  end

  it "returns nil as the token owner for an invalid token" do
    @client.token_owner(@token.reverse).must_be_nil
  end

  it "returns information about the token owner for a valid token" do
    @client.token_owner(@token).must_equal('uuid' => @user['uuid'], 'name' => @user['name'], 'email' => @user['email'], 'type' => 'user')
  end

  it "can create tokens for apps" do
    app = auth_helpers.create_app!
    app_token = @client.create_app_token(app[:id], app[:secret])
    app_token.wont_be_empty

    info = @client.token_owner(app_token)
    info.wont_be_nil
    info['type'].must_equal 'app'
  end

  it "can create venue tokens" do
    app = auth_helpers.create_app!
    app_token = @client.create_app_token(app[:id], app[:secret])

    venue_data = {
      'venue-id' => '12345',
      'name' => 'Peter Smith',
      'email' => 'peter@example.com'
    }

    venue_token = @client.venue_token(app_token, 'facebook', venue_data)

    @client.token_owner(venue_token)['name'].must_equal 'Peter Smith'
  end

  it "can retrieve a users venue identities" do
    app = auth_helpers.create_app!
    app_token = @client.create_app_token(app[:id], app[:secret])

    venue_data = {
      'venue-id' => '12345',
      'name' => 'Peter Smith',
      'email' => 'peter@example.com'
    }

    venue_token = @client.venue_token(app_token, 'facebook', venue_data)
    uuid = @client.token_owner(venue_token)['uuid']

    @client.venue_identities_of(venue_token, uuid).must_equal(
      'facebook' => {'id' => '12345', 'name' => 'Peter Smith'}
    )
  end

  describe "with some venue data" do
    before do
      @venue_data1 = {
        'venue-id' => '12345',
        'name' => 'Peter Smith',
        'email' => 'peter@example.com'
      }

      @venue_data2 = {
        'venue-id' => '4759837',
        'name' => 'Sam Samson',
        'email' => 'sam@example.com'
      }

      @venue_data3 = {
        'venue-id' => '90235',
        'name' => 'Tim Tom',
        'email' => 'timtom@example.com'
      }

      @app = auth_helpers.create_app!
      @app_token = @client.create_app_token(@app[:id], @app[:secret])
    end

    it "can retrieve the venue identities from multiple users at once" do
      venue_token = @client.venue_token(@app_token, 'facebook', @venue_data1)
      uuid1 = @client.token_owner(venue_token)['uuid']
      venue_token = @client.venue_token(@app_token, 'spiral-galaxy', @venue_data2)
      uuid2 = @client.token_owner(venue_token)['uuid']
      venue_token = @client.venue_token(@app_token, 'facebook', @venue_data3)
      uuid3 = @client.token_owner(venue_token)['uuid']

      @client.venue_identities_of(@app_token, uuid1, uuid2, uuid3).must_equal(
        uuid1 => {
          'facebook' => {'id' => @venue_data1['venue-id'], 'name' => @venue_data1['name']}
        },
        uuid2 => {
          'spiral-galaxy' => {'id' => @venue_data2['venue-id'], 'name' => @venue_data2['name']}
        },
        uuid3 => {
          'facebook' => {'id' => @venue_data3['venue-id'], 'name' => @venue_data3['name']}
        }
      )
    end

    it "can attach venue identities to a user" do
      fb_venue_id = {"venue-id" => '85464854', "name" => "Peter S"}
      gs_venue_id = {"venue-id" => "465675795", "name" => "P Smith"}

      uuid = @user['uuid']
      @client.venue_identities_of(@app_token, uuid).empty?.must_equal true

      @client.attach_venue_identity_to(@app_token, uuid, 'facebook',fb_venue_id)
      @client.attach_venue_identity_to(@app_token, uuid, 'spiral-galaxy', gs_venue_id)

      identities = @client.venue_identities_of(@app_token, uuid)
      identities.keys.size.must_equal 2
      identities['facebook'].must_equal("id" => fb_venue_id['venue-id'], "name" => fb_venue_id['name'])
      identities['spiral-galaxy'].must_equal("id" => gs_venue_id['venue-id'], 'name' => gs_venue_id['name'])
    end

    it "does not attach the same id twice" do
      venue_id = {"venue-id" => '295758978', "name" => "Peter S"}
      venue_token = @client.venue_token(@app_token, 'facebook', venue_id)
      uuid = @client.token_owner(venue_token)['uuid']
      @client.attach_venue_identity_to(venue_token, uuid, 'facebook', venue_id)
      identities = @client.venue_identities_of(@app_token, uuid)
      identities.keys.size.must_equal 1
    end

    it "keeps first venue id when attaching a second id of the same venue to one user" do
      fb_venue_id1 = {"venue-id" => '56758492', "name" => "Peter S"}
      fb_venue_id2 = {"venue-id" => '94879502', "name" => "P Smith"}

      venue_token = @client.venue_token(@app_token, 'facebook', fb_venue_id1)
      uuid = @client.token_owner(venue_token)['uuid']
      @client.attach_venue_identity_to(venue_token, uuid, 'facebook', fb_venue_id2)

      identities = @client.venue_identities_of(@app_token, uuid)
      identities["facebook"].must_equal("id" => fb_venue_id1["venue-id"], "name" => fb_venue_id1["name"])
    end

    it "can translate a batch of venue information to QS UUIDs" do
      uuids = @client.uuids_of(@app_token, 'facebook' => [@venue_data1, @venue_data3], 'spiral-galaxy' => [@venue_data2])

      venue_token = @client.venue_token(@app_token, 'facebook', @venue_data1)
      uuid1 = @client.token_owner(venue_token)['uuid']
      venue_token = @client.venue_token(@app_token, 'spiral-galaxy', @venue_data2)
      uuid2 = @client.token_owner(venue_token)['uuid']
      venue_token = @client.venue_token(@app_token, 'facebook', @venue_data3)
      uuid3 = @client.token_owner(venue_token)['uuid']

      uuids['facebook'].keys.size.must_equal 2
      uuids['facebook'][@venue_data1['venue-id']].must_equal uuid1
      uuids['facebook'][@venue_data3['venue-id']].must_equal uuid3

      uuids['spiral-galaxy'].keys.size.must_equal 1
      uuids['spiral-galaxy'][@venue_data2['venue-id']].must_equal uuid2
    end
  end
end
