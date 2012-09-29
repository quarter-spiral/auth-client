# Auth::Client

Client to authenticate auth tokens against the auth-backend.

# Usage

## Verify that a token is valid

```ruby
client = Auth::Client.new
client.token_valid?(your_token) # => true/false
```

## Get information about the token owner

```ruby
client = Auth::Client.new
client.token_owner(your_token) # => {'uuid' => 'some-uuid', 'name' => 'John', 'email' => 'john@example.com'}
```
