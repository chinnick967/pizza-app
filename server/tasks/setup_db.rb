require 'csv'
require 'sequel'

class DB
    def self.initialize
        defaultDb = Sequel.postgres('postgres', :host => 'localhost', :port => 5432, :max_connections => 10)
        defaultDb.run "DROP DATABASE IF EXISTS pizzadb"
        defaultDb.run "CREATE DATABASE pizzadb"

        db = Sequel.postgres('pizzadb', :host => 'localhost', :port => 5432, :max_connections => 10)
        db.create_table :people do
            primary_key :id
            String :name
        end
        db.create_table :orders do
            primary_key :id
            foreign_key :person_id, :people
            String :type
            DateTime :eaten_at
        end

        people = db[:people]
        orders = db[:orders]
        csv = CSV.parse(File.read("#{File.dirname(__FILE__)}/../data/data.csv"), headers: true)
        csv.each do |row|
            if people.where(:name => row['person']).count == 0
                people.insert(:name => row['person'])
            end
            orders.insert(:type => row['meat-type'], :eaten_at => row['date'], :person_id => people.where(:name => row['person']).map(:id)[0])
        end

        puts "Database has been setup"
    end
end

DB.initialize()