ENV['RACK_ENV'] ||= 'test'

Bundler.require

require 'minitest/autorun'
require 'rack/client'

require 'auth-client'
require 'auth-backend'
require 'auth-backend/test_helpers'
require 'graph-backend'

GRAPH_BACKEND = Graph::Backend::API.new
module Auth::Backend
  class Connection
    alias raw_initialize initialize
    def initialize(*args)
      result = raw_initialize(*args)

      graph_adapter = Service::Client::Adapter::Faraday.new(adapter: [:rack, GRAPH_BACKEND])
      @graph.client.raw.adapter = graph_adapter
    end
  end
end

AUTH_APP = Auth::Backend::App.new(test: true)

AUTH_CLIENT = Auth::Client.new('http://auth-backend.dev', adapter: [:rack, AUTH_APP])
AUTH_HELPERS = Auth::Backend::TestHelpers.new(AUTH_APP)