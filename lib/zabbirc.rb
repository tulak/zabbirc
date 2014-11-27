require 'active_support/all'
require 'singleton'
require 'dotenv'
require 'yaml'
Dotenv.load

def require_dir dir
  base_dir = Pathname.new(File.expand_path(File.dirname(__FILE__)))
  Dir.glob(base_dir.join(dir)).each do |f|
    require f
  end
end

module Zabbirc
  RUNTIME_DATA_DIR = Pathname.new("/var/run/zabbirc") unless defined? RUNTIME_DATA_DIR
  def self.synchronize &block
    @mutex ||= Mutex.new
    @mutex.synchronize &block
  end
end

require_dir "zabbirc/*.rb"
require_dir "zabbirc/irc/*.rb"
require 'zabbirc/zabbix/resource/base'
require_dir "zabbirc/zabbix/*.rb"
require 'zabbirc/services/base'
require_dir "zabbirc/services/*.rb"