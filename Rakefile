# -----------------------------------------------------------------------------
# Libraries
# -----------------------------------------------------------------------------
require 'yaml'
require 'json'
require 'erb'
require 'ostruct'
require_relative 'lib/packer/iso'
require_relative 'lib/packer/variables'
require_relative 'lib/password_factory'

# -----------------------------------------------------------------------------
# Globals
# -----------------------------------------------------------------------------
TEMPLATE_DIR   = 'templates'
PACKER_HCL_DIR = 'packer'
BUILD          = Regexp.new(ENV.fetch('BUILD', '.*'))
ONLY           = ENV.fetch('ONLY', '*')
TARGET         = ENV.fetch('TARGET', 'server')
FIRMWARE       = ENV.fetch('FIRMWARE', 'efi')
HEADLESS       = ENV.fetch('HEADLESS', true)
PACKER_LOG     = ENV.fetch('PACKER_LOG', 1)
LOG_DIR        = 'logs'
ISO_DIR        = 'iso'

Rake::FileList["#{PACKER_HCL_DIR}/*.pkrvars.hcl"].each do |hcl|
  basename = hcl.pathmap('%n').ext
  task = Rake::Task.define_task("build:#{basename}-server-efi")
  task.add_description("#{basename} build")
end

# -----------------------------------------------------------------------------
# Classes
# -----------------------------------------------------------------------------
class Hash
  # expand packer variables
  def from_var
    h = self.map do |k, v|
      v = v.gsub(%r{\{\{\s*user\s+`(.*?)`\}\}}) { self[$1] }
      [k, v]
    end
    h.to_h
  end
end

# -----------------------------------------------------------------------------
# Methodds
# -----------------------------------------------------------------------------
def destination_dir
  dirs = []
  Rake::FileList["#{PACKER_HCL_DIR}/*.pkrvars.hcl"].each do |hcl|
    vars = Packer::Variables.from(hcl)
    dirs << vars.fetch('destination_dir', [])
  end
  dirs.flatten.uniq
end

def override_variables(config)
  config = config.map do |key, value|
    [key, ENV.fetch(key.upcase, value)]
  end
  config = config.to_h
  # hacky little trick - for now
  config['firmware'] = FIRMWARE
  config
end

def assemble_config(hcl_file)
    config = Packer::Variables.from(hcl_file)
    config = override_variables(config)
    iso_file = File.join(ISO_DIR, config['dist_name'], config['iso_file'])
    config['volume_id'] = Packer::ISO.volume_id(iso_file)
    environment(config)
    write_config(config)
    config
end

def header(file)
  line   = '-' * 78
  header = <<~HEADER
    # #{line}
    # Generated from #{file}
    # All changes made to this file will be lost!
    # #{line}
    HEADER
end

def write_config(config)
  dir  = config['dist_name']
  glob = File.join(TEMPLATE_DIR, dir, '*.erb')
  Rake::FileList[glob].each do |template|
    basename = File.basename(template.ext)
    out_file = File.join(config['http_dir'], dir, basename)
    content  = File.read(template)
    header   = header(template)
    mkdir_p File.dirname(out_file)
    File.open(out_file, 'w') do |fh|
      puts "Writing config file '#{out_file}'"
      fh.write ERB.new(content).result(binding)
    end
  end
end

def environment(config)
  ENV['FIRMWARE']        = FIRMWARE
  ENV['TARGET']          = TARGET
  ENV['PACKER_LOG']      = PACKER_LOG.to_s
  ENV['PACKER_LOG_PATH'] = File.join(LOG_DIR, config['dist_name'] + ".log")
end

def accelerator
  case
  when File.exist?('/dev/kvm') then 'kvm'
  else 'none'
  end
end

# -----------------------------------------------------------------------------
# Directories
# -----------------------------------------------------------------------------
directory LOG_DIR

# -----------------------------------------------------------------------------
# Namespaces
# -----------------------------------------------------------------------------
namespace :clean do
  desc "Clean up all generated files"
  task :all => [:build_cache, :logs]

  desc "Clean logs"
  task :logs do
    rm_rf LOG_DIR
  end

  desc "Clean build cache"
  task :build_cache do
    (destination_dir + %w( packer_cache tmp http)).each do |dir|
      rm_rf dir
    end
  end
end

namespace :build do
  task :find do
  end
end

# -----------------------------------------------------------------------------
# Tasks
# -----------------------------------------------------------------------------
task :default => :build

desc "Only the various configuration files"
task :config do
  @var_files = []
  Rake::FileList["#{PACKER_HCL_DIR}/*.pkrvars.hcl"].each do |hcl|
    next unless hcl =~ BUILD
    assemble_config(hcl)
    @var_files.push(hcl)
  end
end

desc "Build OS images"
task :build => [LOG_DIR, :config] do
  @var_files.each do |hcl|
    config = assemble_config(hcl)
    sh %(packer build ) +
       %( -color=#{$stdout.isatty} ) +
       %( -parallel-builds 1 ) +
       %( -var "target=#{TARGET}" ) +
       %( -var "headless=#{HEADLESS}" ) +
       %( -var "firmware=#{FIRMWARE}" ) +
       %( -var "accelerator=#{accelerator}" ) +
       %( -var "volume_id=#{config['volume_id']}" ) +
       %( -var-file "#{hcl}" ) +
       %( -only "#{ONLY}" ) +
       %( #{PACKER_HCL_DIR} ) do |ok,res| end
  end
end
