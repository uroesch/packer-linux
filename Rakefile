# -----------------------------------------------------------------------------
# Libraries
# -----------------------------------------------------------------------------
$LOAD_PATH.unshift(File.expand_path('lib'))
require 'yaml'
require 'json'
require 'erb'
require 'ostruct'
require 'packer'
require 'password_factory'

# -----------------------------------------------------------------------------
# Globals
# -----------------------------------------------------------------------------
VERSION        = '0.13.0'
PACKER_HCL_DIR = 'packer'
BUILD          = Regexp.new(ENV.fetch('BUILD', '.*'))
ONLY           = ENV.fetch('ONLY', '*')
TARGET         = ENV.fetch('TARGET', 'server')
FIRMWARE       = ENV.fetch('FIRMWARE', 'efi')
HEADLESS       = ENV.fetch('HEADLESS', true)
PACKER_LOG     = ENV.fetch('PACKER_LOG', 1)
LOG_DIR        = 'logs'
ISO_DIR        = 'iso'
TEMPLATE_DIR   = 'templates'
DISKLAYOUT_DIR = File.join(TEMPLATE_DIR, 'disklayouts', TARGET)


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
def pkrvars_files(mode = 'all')
  files = Rake::FileList["#{PACKER_HCL_DIR}/*.pkrvars.hcl"]
  case mode
  when 'ex_auto' then files.delete_if { |x|  x =~ %r{\.auto\.} }
  when 'only_auto' then p files.select { |x|  x =~ %r{\.auto\.} }
  else files
  end
end

def destination_dir
  dirs = []
  pkrvars_files.each do |hcl|
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

def parse_auto_config
  pkrvars_files('only_auto').inject({}) do |config, hcl_file|
    config.merge(Packer::Variables.from(hcl_file))
  end
end

def assemble_config(hcl_file)
    config = parse_auto_config.merge(Packer::Variables.from(hcl_file))
    config = override_variables(config)
    iso_file = File.join(ISO_DIR, config['dist_name'], config['iso_file'])
    config['volume_id'] = Packer::ISO.volume_id(iso_file)
    config = Packer::Disklayout.load(DISKLAYOUT_DIR, config)
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
  desc 'Clean up iso, images, logs and cached files'
  task :all => [:volatile, :images, :iso]
  
  desc 'Clean up all volatile files like logs and build cache'
  task :volatile => [:build_cache, :logs]

  desc 'Clean disk images'
  task :images do
    rm Rake::FileList['images/*']
  end

  desc 'Clean non base build disk images'
  task :non_base_images do
    rm Rake::FileList['images/*'].exclude(%r{\.qcow2})
  end

  desc 'Clean iso images'
  task :iso do
    rm Rake::FileList["#{ISO_DIR}/*/*.iso"]
  end

  desc 'Clean logs'
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

namespace :install do
  desc "Install novnc systemd service"
  task :novnc => [ :package, :service ]

  task :scripts do
    sh %(sudo install -o root -g root -m 755 install/novnc_proxy /usr/local/bin)
    sh %(sudo install -o root -g root -m 755 install/vnc-proxy.sh  /usr/local/bin)
  end

  task :service => :scripts do
    sh %(sudo install -o root -g root -m 644 install/novnc.service /etc/systemd/system/)
    sh %(sudo systemctl daemon-reload)
    sh %(sudo systemctl enable novnc.service)
  end

  task :package do
    sh %(sudo apt install novnc)
  end
end

namespace :build do
  task :find do
  end
end

namespace :iso do
  desc 'List all ISO urls from the packer variable files'
  task :list_urls do
    pkrvars_files('ex_auto').each do |hcl|
      config = Packer::Variables.from(hcl)
      url    = File.join(config.values_at('iso_base_url', 'iso_file'))
      puts url if url.start_with?(%r{https?://})
    end
  end
end

namespace :scaffold do
  task :copy_from do
    version = ENV.fetch('VERSION', false)
    name    = ENV.fetch('NAME', false)
    from    = ENV.fetch('FROM', false)

    [version, name, from].select { |x| ! x }.count != 0

    basename = [name, version].join('_')
    cd PACKER_HCL_DIR do
      cp "#{from}.pkrvars.hcl", "#{basename}.pkrvars.hcl"
    end

    cd TEMPLATE_DIR do
      ln_s from, basename
    end

    cd ISO_DIR do
      mkdir basename
    end
  end
end

# -----------------------------------------------------------------------------
# Prerequisites
# -----------------------------------------------------------------------------
pkrvars_files('ex_auto').each do |hcl|
  basename = hcl.pathmap('%n').ext
  task = Rake::Task.define_task("build:#{basename}-server-efi")
  task.add_description("#{basename} build")
end

# -----------------------------------------------------------------------------
# Tasks
# -----------------------------------------------------------------------------
task :default => :build


desc "Only the various configuration files"
task :config do
  @var_files = []
  pkrvars_files('ex_auto').each do |hcl|
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
       %( -var "boot_wait=#{config['boot_wait']}" ) +
       %( -var "ssh_wait_timeout=#{config['ssh_wait_timeout']}" ) +
       %( -var-file "#{hcl}" ) +
       %( -only "#{ONLY}" ) +
       %( #{PACKER_HCL_DIR} ) do |ok,res| end
  end
end
