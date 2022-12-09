module Packer
  class Host

    VIRTUAL_VENDORS = %w(
      vmware
      qemu
    )

    def self.is_virtual?
      hardware_vendors.grep(Regexp.union(VIRTUAL_VENDORS)).count > 0
    end

    def self.hardware_vendors
      @vendors ||= `lshw 2>/dev/null`.split("\n").inject([]) do |vendors, line|
        line.downcase!
        vendors << line.split(':').last.strip if line.include?('vendor:')
        vendors.uniq
      end
    end
  end
end
