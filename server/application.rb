require 'grape'

Dir["#{File.dirname(__FILE__)}/app/api/**/*.rb"].each { |f| require f }

module API
    class Root < Grape::API
        format :json
        prefix :api

        get :status do
            { status: 'ok' }
        end
    end
end

Application = Rack::Builder.new do
    map "/" do
        run API::Root
    end
end