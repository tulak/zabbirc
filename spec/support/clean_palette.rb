class CleanPalette
  def format tokens
    tokens.reject do |token|
      token.is_a? Array
    end.join.gsub(/ +/," ").strip
  end
end

def Zabbirc.rich_text_formatter
  @rich_text_formatter ||= Zabbirc::RichTextFormatter.new(CleanPalette)
end