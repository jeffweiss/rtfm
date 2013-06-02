require 'sinatra'
require 'sinatra-websocket'
require 'pg'
require 'json'
require 'stomp'


set :sockets, Hash.new {|hash, key| hash[key] = []}

set :db_conn, PG.connect( :dbname => 'rtfm', :user => 'rtfm', :password => 'rtfm', :host => ARGV[2])

set :stomp_login_hash, {
  :hosts => [ { :login => ARGV[0], :passcode => ARGV[1], :host => ARGV[2], :port => 61613, :ssl => true}]
}

set :stomp_client, Stomp::Client.new(settings.stomp_login_hash)
set :topic_prefix, "/topic/"

set :current_fact, "memoryfree_mb"

get '/subscribe/:fact' do |fact|
  if request.websocket?
    begin
      settings.stomp_client.subscribe(settings.topic_prefix+fact) do |msg|
        hash = JSON.parse(msg.body)
        values_json = hash.values.map(&:to_s).to_json
        settings.sockets[fact].each {|s| s.send(values_json) }
      end
    rescue
      warn("we're probably already subscribed to that fact")
    end

    request.websocket do |ws|
      ws.onopen do
        settings.sockets[fact] << ws
      end

      ws.onmessage do |msg|
        #throw it away
        EM.next_tick { settings.sockets[fact].each{|s| s.send("server fact echo: #{msg}") } }
      end

      ws.onclose do
        warn "websocket closed"
        settings.sockets[fact].delete(ws)
      end
    end
  end
end

get '/fact/:fact' do |fact|
  settings.db_conn.exec('select extract(epoch from tstamp at time zone \'pdt\') as tstamp, value from facts where name = $1 order by tstamp desc limit 25', [fact]).values.to_json
end

get '/' do
  erb :index, :locals => { :current_fact => settings.current_fact }
end

get '/view/:fact' do |fact|
  erb :index, :locals => { :current_fact => fact }
end