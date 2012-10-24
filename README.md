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
  venue_id: '053324235',
  name:     'Peter Smith',
  email:    'peter@example.com'
}
client = Auth::Client.new(auth_backend_url)
client.venue_token(app_token, 'facebook', venue_options) # => '123456...'
```
