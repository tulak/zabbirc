def Zabbirc.rich_text_formatter
  @rich_text_formatter ||= Zabbirc::RichTextFormatter.new(Zabbirc::Palettes::Clean)
end