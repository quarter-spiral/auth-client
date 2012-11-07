ENV['RACK_ENV'] ||= 'test'

Bundler.require

require 'minitest/autorun'
require 'rack/client'

require 'auth-client'
require 'auth-backend'
require 'graph-backend'
