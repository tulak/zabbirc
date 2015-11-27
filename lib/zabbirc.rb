require 'active_support/all'
require 'singleton'
require 'dotenv'
require 'yaml'
require 'pathname'
Dotenv.load

def require_dir dir
  base_dir = Pathname.new(File.expand_path(File.dirname(__FILE__)))
  Dir.glob(base_dir.join(dir)).each do |f|
    require f
  end
end

module Zabbirc
  LIB_DATA_DIR = Pathname.new("/usr/local/zabbirc") unless defined? LIB_DATA_DIR
  def self.synchronize &block
    @mutex ||= Mutex.new
    @mutex.synchronize &block
  end

  def self.events_id_shortener
    @events_id_shortener ||= IdShortener.new
  end

  def self.maintenances_id_shortener
    @maintenances_id_shortener ||= IdShortener.new
  end

  def self.rich_text_formatter
    @rich_text_formatter ||= begin
      palette = (config.colors ? Palettes::Default : Palettes::Clean)
      RichTextFormatter.new palette
    end
  end
end

require 'zabbirc/configuration'
require_dir "zabbirc/*.rb"
require 'zabbirc/irc/base_command'
require_dir "zabbirc/irc/*.rb"
require 'zabbirc/zabbix/resource/base'
require_dir "zabbirc/zabbix/*.rb"
require 'zabbirc/services/base'
require_dir "zabbirc/services/*.rb"

