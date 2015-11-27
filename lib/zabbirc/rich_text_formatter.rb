require_dir 'zabbirc/palettes/*'

module Zabbirc
  class RichTextFormatter
    DEFAULT_PALETTE = Zabbirc::Palettes::Default
    COMMANDS = %w[C B U RST] # C - color, B - bold, U - underlined, RST - reset all formatting
    COMMANDS_REGEXP = Regexp.union(COMMANDS)
    delegate :paint, to: :pallete
    def initialize palette=DEFAULT_PALETTE
      @palette = palette.new
    end

    def format msg
      tokens = tokenize msg
      @palette.format tokens
    end

    private
    def tokenize msg
      r = /\$(?<cmd>#{COMMANDS_REGEXP})(?<args>(,[a-zA-Z0-9_]+)*)\$(?<rest>(?:[\n\r]|.)*)/
      match_data = msg.match(r)
      return [msg] if match_data.nil?
      args = match_data[:args].split(/,/).reject(&:blank?)
      cmd = [
          match_data[:cmd].to_sym,
          args
      ].flatten
      ([match_data.pre_match, cmd] + tokenize(match_data[:rest])).reject(&:nil?)
    end

  end
end