module Packer
  class Disklayout
    require 'erb'
    require 'pp'

    ERB_EXT     = '.erb'
    DEFAULT_DIR = 'default'

    def self.load(base_dir, config)
      @base_dir   = base_dir
      parse(config)
    end

    def self.template_dir
      return @base_dir if File.directory?(@base_dir) 
      @base_dir = File.join(File.dirname(@base_dir), DEFAULT_DIR)
      if File.directory?(@base_dir)
        @base_dir
      else
        raise("Could not locate #{base_dir}")
      end
    end

    def self.parse(config)
      dir  = template_dir
      glob = File.join(dir, '*' << ERB_EXT)
      config['disklayout'] ||= {}
      Dir[glob].each do |path|
        content = File.read(path)
        name    = File.basename(path, ERB_EXT)
        config['disklayout'][name] = ERB.new(content).result(binding)
      end
      config
    end
  end
end
