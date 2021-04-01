require 'grape'
require 'sequel'

Dir["#{File.dirname(__FILE__)}/app/api/**/*.rb"].each { |f| require f }

module API
    class Root < Grape::API
        format :json
        prefix :api

        before do
            header "Access-Control-Allow-Origin", "*"
        end

        helpers do
            def fetch_all_people
                db = Sequel.postgres('pizzadb', :host => 'localhost', :port => 5432, :max_connections => 10)
                db[:people].all
            end
            def fetch_all_orders
                db = Sequel.postgres('pizzadb', :host => 'localhost', :port => 5432, :max_connections => 10)
                db[:orders].all
            end
            def order_streaks
                db = Sequel.postgres('pizzadb', :host => 'localhost', :port => 5432, :max_connections => 10)
                # Find all orders that are in a streak, group them, and count the streak
                # BUG: For some reason one extra row (1-2-2015) shows up, unresolved
                db.fetch("
                    SELECT
                        MIN(eaten_at) as startdate,
                        COUNT(*) as streak
                    FROM (
                        SELECT
                            *,
                            ROW_NUMBER() OVER(ORDER BY eaten_at)  - ROW_NUMBER() OVER(PARTITION BY isinstreak ORDER BY eaten_at) grp
                        FROM (
                            SELECT
                                date_part('month', eaten_at) AS month,
                                date_part('day', eaten_at) AS day,
                                eaten_at,
                                (count < LEAD(count) OVER (ORDER BY (eaten_at))
                                    OR (count > LAG(count) OVER (ORDER BY (eaten_at)) AND count > LEAD(count) OVER (ORDER BY (eaten_at)))) as isinstreak
                            FROM (
                                SELECT
                                    eaten_at,
                                    COUNT(*) as count
                                FROM orders
                                GROUP BY eaten_at
                                ORDER BY eaten_at
                            ) groupedorders
                        ) sorders
                        WHERE sorders.isinstreak IS NOT NULL
                    ) gorders
                    GROUP BY grp
                    ORDER BY MIN(eaten_at)
                ").all
            end
            def fetch_most_daily_orders_in_each_month
                db = Sequel.postgres('pizzadb', :host => 'localhost', :port => 5432, :max_connections => 10)
                # Room for improvement: If there are 2+ dates with the same number of orders, only returns the first one
                db.fetch("SELECT *
                            FROM (
                                SELECT
                                    date_part('month', eaten_at) AS month,
                                    date_part('day', eaten_at) AS day,
                                    COUNT(*) AS count
                                FROM orders GROUP BY day, month) dates 
                                WHERE (month, count) 
                                    IN (SELECT
                                            month,
                                            MAX(count)
                                        FROM (SELECT date_part('day', eaten_at) AS day, date_part('month', eaten_at) AS month, COUNT(*) AS count FROM orders GROUP BY day, month) dates
                                        GROUP BY month)
                        ORDER BY month").all
            end
        end

        resource :people do
            get :all do
                fetch_all_people
            end
        end

        resource :orders do
            get :all do
                fetch_all_orders
            end

            get :streaks do
                order_streaks
            end

            get :bestmonth do
                fetch_most_daily_orders_in_each_month
            end
            
            desc "Delete a row from the table"
            params do
                requires :id
            end
            delete ':id' do
                { test: 'test delete' }
            end
        end

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