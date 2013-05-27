require 'sinatra'
require 'pg'
require 'json'

db_conn = PG.connect( :dbname => 'rtfm', :user => 'rtfm', :password => 'rtfm', :host => ARGV[2])

get '/fact/:fact' do |fact|
  db_conn.exec('select extract(epoch from tstamp) as tstamp, value from facts where name = $1', [fact]).values.to_json
end

get '/' do
  erb :index, :locals => { :current_fact => "memoryfree_mb" }
end
