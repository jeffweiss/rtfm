require 'rb-notify'
require 'json'

notifier = INotify::Notifier.new

dir = "/tmp/facts/spool"

notifier.watch(dir, :moved_to, :close_write) do |event|
  filename = File.join(dir, event.name)
  begin
    contents = File.read(filename)
    contents_as_json = JSON.parse(contents)
    puts "retrieved facts from #{contents_as_json['timestamp']}"
  rescue
    puts "error reading contents of #{filename}"
  end
end

notifier.run
