require 'json'
require 'stomp'
require 'pg'

stomp_login_hash = {
  :hosts => [ { :login => ARGV[0], :passcode => ARGV[1], :host => ARGV[2], :port => 61613, :ssl => true}]
}

client = Stomp::Client.new(stomp_login_hash)
queue_name = "/queue/rtfm"
topic_prefix = "/topic/"

db_conn = PG.connect( :dbname => 'rtfm', :user => 'rtfm', :password => 'rtfm', :host => ARGV[2] )

statement_name = 'fact_insert'

db_conn.prepare(statement_name, 'insert into facts (tstamp, name, value) values (to_timestamp( cast($1 as numeric) / 1000), $2, $3);')

client.subscribe(queue_name, {:ack => "client", "activemq.prefetchSize" => 1, "activemq.exclusive" => true }) do |msg|
  now = (Time.now.to_f*1000).to_i
  puts "we got a message"
#  puts msg.inspect
  json = JSON.parse(msg.body)
  run_time = (json["timestamp"]*1000).to_i
  enqueue_time = msg.headers["timestamp"]
  puts "  -- initial run at #{run_time}"
  puts "  -- enqueued at    #{enqueue_time}"
  puts "  -- now            #{now}"
  puts "  == total time = #{now - run_time}ms" 
  File.open("/tmp/#{Time.now.to_f}.json", "w") do |f|
    f.puts msg.body
  end
  json["facts"].each do |k, v|
    db_conn.exec_prepared(statement_name, [run_time, k, v])
    client.publish topic_prefix+k, json["timestamp"].to_s
  end
  client.acknowledge(msg)
  puts "done writing to db and topics"
  puts "------"
end
client.join
