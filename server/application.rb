require 'grape'
require 'sequel'

Dir["#{File.dirname(__FILE__)}/app/api/**/*.rb"].each { |f| require f }

Application = Rack::Builder.new do
    map "/" do
        run API::Root
    end
end