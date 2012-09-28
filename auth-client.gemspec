# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'auth-client/version'

Gem::Specification.new do |gem|
  gem.name          = "auth-client"
  gem.version       = Auth::Client::VERSION
  gem.authors       = ["Thorben Schröder"]
  gem.email         = ["thorben@quarterspiral.com"]
  gem.description   = %q{Client to authenticate auth tokens against the auth-backend}
  gem.summary       = %q{Client to authenticate auth tokens against the auth-backend}
  gem.homepage      = ""

  gem.files         = `git ls-files`.split($/)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]

  gem.add_dependency 'service-client'
end
