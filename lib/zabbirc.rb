require 'active_support/all'
require 'pry'
require 'singleton'
require 'dotenv'
Dotenv.load

def require_dir dir
  base_dir = Pathname.new(File.expand_path(File.dirname(__FILE__)))
  Dir.glob(base_dir.join(dir)).each do |f|
    require f
  end
end

module Zabbirc
  def self.synchronize &block
    @mutex ||= Mutex.new
    @mutex.synchronize &block
  end
end

require_dir "zabbirc/*.rb"
require_dir "zabbirc/irc/*.rb"
require 'zabbirc/zabbix/resource/base'
require_dir "zabbirc/zabbix/*.rb"
require_dir "zabbirc/services/*.rb"

# require_relative "../config/config"

# include Zabbirc::Zabbix
# s = Zabbirc::Service.new
# binding.pry