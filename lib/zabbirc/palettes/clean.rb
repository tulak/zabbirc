module Zabbirc
  module Palettes
    class Clean
      def format tokens
        tokens.reject do |token|
          token.is_a? Array
        end.join.gsub(/ +/," ").strip
      end
    end
  end
end