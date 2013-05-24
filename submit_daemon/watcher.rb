require 'rb-notify'
require 'json'

notifier = INotify::Notifier.new

dir = "/tmp/facts/spool"

stomp_login_hash = {
  :hosts => [ { :login => ARGV[0], :passcode => ARGV[1], :host => ARGV[2], :port => 61613, :ssl => true}]
}
client = Stomp::Client.new(stomp_login_hash)
queue_name = "/queue/rtfm"

notifier.watch(dir, :moved_to, :close_write) do |event|
  filename = File.join(dir, event.name)
  begin
    contents = File.read(filename)
    contents_as_json = JSON.parse(contents)
    puts "retrieved facts from #{contents_as_json["timestamp"]}"
    client.publish queue_name, contents, {:persistent => true}
    puts "  -- published to #{queue_name}"
  rescue
    puts "error reading contents of #{filename}"
  end
end

notifier.run
