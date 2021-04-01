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
            def deleteFromDB(table, id)
                db = Sequel.postgres('pizzadb', :host => 'localhost', :port => 5432, :max_connections => 10)
                db[table].where(id: id).delete
            end
            def addToOrders(person_id, type, eaten_at)
                db = Sequel.postgres('pizzadb', :host => 'localhost', :port => 5432, :max_connections => 10)
                db[:orders].insert(:person_id => person_id, :type => type, :eaten_at => eaten_at)
            end
            def updateOrder(id, column, value)
                db = Sequel.postgres('pizzadb', :host => 'localhost', :port => 5432, :max_connections => 10)
                db[:orders].where(id: id).update(column => value)
            end
        end

        resource :people do
            desc "Fetch all people"
            get :all do
                fetch_all_people
            end

            desc "Delete a row from the table using the ID"
            params do
                requires :id, :table
            end
            delete ':id' do
                deleteFromDB(params[:table], params[:id])
            end
        end

        resource :orders do
            desc "Fetch all orders"
            get :all do
                fetch_all_orders
            end

            desc "Fetch all streaks of orders where more pizza was ordered the next day"
            get :streaks do
                order_streaks
            end

            desc "Fetch the best day for orders for each month"
            get :bestmonth do
                fetch_most_daily_orders_in_each_month
            end
            
            desc "Delete a row from the table using the ID"
            params do
                requires :id, :table
            end
            delete ':id' do
                deleteFromDB(params[:table], params[:id])
            end
            
            desc "Add an order"
            params do
                requires :person_id, :type, :eaten_at
            end
            post :addOrder do
                addToOrders(params[:person_id], params[:type], params[:eaten_at])
            end

            desc "Update an order"
            params do
                requires :id, :column, :value
            end
            put :updateOrder do
                updateOrder(params[:id], params[:column], params[:value])
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