module Packer
  class ISO
    def self.volume_id(iso_file)
       volume_id = nil
       return volume_id unless File.exist?(iso_file)
       `isoinfo -d -i #{iso_file}`.lines do |line|
          next unless line =~ %r{^Volume id:}
          volume_id = line.split(%r{:\s+}).last 
          return volume_id.strip
       end 
    end
  end
end
