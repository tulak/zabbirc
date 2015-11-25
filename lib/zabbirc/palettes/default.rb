module Zabbirc
  module Palettes
    class Default
      COLORS = {
          "white" => 0,
          "black" => 1,
          "blue" => 2,
          "green" => 3,
          "red" => 4,
          "brown" => 5,
          "purple" => 6,
          "orange" => 7,
          "yellow" => 8,
          "light_green" => 9,
          "blue_cyan" => 10,
          "light_cyan" => 11,
          "light_blue" => 12,
          "pink" => 13,
          "grey" => 14,
          "light_grey" => 15
      }
      COMMANDS = {
          bold: "\x02",
          color: "\x03",
          underlined: "\x1F",
          reset: "\x0F"
      }
      RESET_ARG = "RST"

      def format tokens
        @flags = Hash.new(false)
        tokens.collect do |token|
          process_token token
        end.join
      end

      private
      def process_token token
        case token
        when Array
          cmd = token.shift
          case cmd
          when :C then process_color token
          when :B then process_bold token
          when :U then process_underline token
          when :RST then process_reset token
          else
            raise ArgumentError, "unknown irc richtext command `#{cmd.inspect}`"
          end
        when String then token
        else
          raise ArgumentError, "unknown token `#{token.inspect}`"
        end
      end

      def process_color args
        raise ArgumentError, "too many arguments for C command" if args.size > 2
        fg, bg = args.compact
        return COMMANDS[:color] if fg == RESET_ARG
        fg = "%02d" % COLORS[fg.downcase] if fg.present?
        bg = "%02d" % COLORS[bg.downcase] if bg.present?
        colors = [fg,bg].compact.join(",")
        "#{COMMANDS[:color]}#{colors}"
      end

      def process_bold args
        raise ArgumentError, "too many arguments for B command" if args.size > 1
        case args.first
        when RESET_ARG
          return unless @flags[:bold]
          @flags[:bold] = false
          COMMANDS[:bold]
        else
          return if @flags[:bold]
          @flags[:bold] = true
          COMMANDS[:bold]
        end
      end

      def process_underline args
        raise ArgumentError, "too many arguments for U command" if args.size > 1
        case args.first
        when RESET_ARG
          return unless @flags[:underlined]
          @flags[:underlined] = false
          COMMANDS[:underlined]
        else
          return if @flags[:underlined]
          @flags[:underlined] = true
          COMMANDS[:underlined]
        end
      end

      def process_reset args
        raise ArgumentError, "too many arguments for RST command" unless args.size.zero?
        @flags = Hash.new(false)
        COMMANDS[:reset]
      end
    end
  end
end