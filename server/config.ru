require 'rack/cors'

require File.expand_path('../application', __FILE__)

use Rack::Cors do
    allow do
      origins '*'
      resource '*', headers: :any, methods: [:get, :post, :delete, :put, :patch, :options, :head]
    end
end

run Application