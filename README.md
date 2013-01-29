# Auth::Client

Client to authenticate auth tokens against the auth-backend.

# Usage

## Obtain an OAuth token with OAuth client/app credentials

```ruby
client = Auth::Client.new(auth_backend_url)
token = client.create_app_token(app_id, app_secret) # => '123456...'
```

## Verify that a token is valid

```ruby
client = Auth::Client.new(auth_backend_url)
client.token_valid?(your_token) # => true/false
```

## Get information about the token owner

```ruby
client = Auth::Client.new(auth_backend_url)
client.token_owner(your_token) # => {'uuid' => 'some-uuid', 'name' => 'John', 'email' => 'john@example.com'}
```

## Create a token for a venue user

```ruby
venue_options = {
  "venue-id" => '053324235',
  "name" =>     'Peter Smith',
  "email" =>    'peter@example.com'
}
client = Auth::Client.new(auth_backend_url)
client.venue_token(app_token, 'facebook', venue_options) # => '123456...'
```

## Retrieve a user's venue identities

```ruby
client = Auth::Client.new(auth_backend_url)
venues = client.venue_identities_of(token, user_uuid)
venues # => {'facebook' => {'id' => '1234', name => 'Peter Smith'}}
```

## Retrieve venue identities for multiple users at once

```ruby
client = Auth::Client.new(auth_backend_url)
user_venues = client.venue_identities_of(token, user_uuid1, user_uuid2, user_uuid3)
user_venues[user_uuid1] # => {'facebook' => {'id' => '1234', name => 'Peter Smith'}}
…
```

## Attach a venue identity to a user

```ruby
client = Auth::Client.new(auth_backend_url)
venue_identity = {"venue-id" => "053324235", "name" => "Peter Smith"}
venue = 'facebook'
client.attach_venue_identity_to(token, uuid, venue, venue_identity)
```

## Retrieve UUIDs for a batch of users identified by their venue
ientities

```ruby
client = Auth::Client.new(auth_backend_url)
venue_data = {
  "facebook" => [
    {"venue-id" => "053324235", "name" => "Peter Smith"},
    {"venue-id" => "489574598", "name" => "Sam Jackson"}
  ],
  "spiral-galaxy" => [
    {"venue-id" => "562090343", "name" => "Jack Tumbler"}
  ]
}

uuids = client.uuids_of(token, venue_data)

uuids # => {
      #      'facebook' => {
      #        '053324235' => '9643598988',
      #        '489574598' => '8934098502'
      #      },
      #      'spiral-galaxy' => {
      #        '562090343' => '8350483509'
      #      }
      #    }
```
