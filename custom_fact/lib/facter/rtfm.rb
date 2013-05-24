require 'json'

Facter.add(:rtfm) do
  setcode do
    timestamp = Time.now
    at_exit do
      File.open("/tmp/facts-#{timestamp.to_i}.json", "w") do |f|
        hash = { :timestamp => timestamp.to_f, :facter => Facter.collection.to_hash }
        f.puts hash.to_json
      end
    end
    "set"
  end
end
