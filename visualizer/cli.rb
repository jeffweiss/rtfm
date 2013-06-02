require 'pg'
require 'stomp'
require 'json'

stomp_login_hash = {
  :hosts => [ { :login => ARGV[0], :passcode => ARGV[1], :host => ARGV[2], :port => 61613, :ssl => true}]
}

client = Stomp::Client.new(stomp_login_hash)
topic_prefix = "/topic/"

client.subscribe(topic_prefix+ARGV[3]) do |msg|
  puts msg.body
end

client.join
