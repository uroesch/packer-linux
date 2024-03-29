module Packer
  class Variables
    require 'pp'

    def self.from(file)
      hcl = self.new(file)
      hcl.parse
      hcl.overrides
    end

    def self.dump(file)
      pp from(file)
    end

    def initialize(file)
      @file = file
      @vars = {}
    end

    def parse
      begin
        File.exist?(@file)
        content = File.read(@file)
        # remove comments
        content = content.gsub(%r{/\*.*?\*/}m, '')
        content = content.gsub(%r{=\s*\[(.*?)\]}m) { |x| x.gsub(%r{\s*\n\s*}, '') }
        content.each_line do |line|
          line.strip!
          next if line.empty?
          next if line.start_with?(%r{#|//})
          key, value = line.split(%r{\s*=\s*})
          value      = value.to_s.gsub(%r{^["']|["']$}, '')
          @vars[key] = value
        end
      end
      # expand the parser to locals to get this value
    end

    def overrides
      boot_wait
      dist_name
      full_name
      ssh_wait_timeout
      @vars
    end

    def full_name
      minor = @vars.fetch('version_minor', nil)
      @vars['full_version'] = [dist_name, minor].compact.join('.')
    end

    def dist_name
      @vars['dist_name'] = @vars.values_at('name', 'version').join('_')
    end

    def boot_wait
      @vars['boot_wait'] = Packer::Host.is_virtual? ? '5s' : '3s'
    end

    def ssh_wait_timeout
      @vars['ssh_wait_timeout'] = Packer::Host.is_virtual? ? '45m' : '30m'
    end
  end
end
