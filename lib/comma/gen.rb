class Enumerator::Generator
  def to_comma(style = :default)
    Comma::Generator.new(self, style).run(:each)
  end

  def empty?
    self.end?
  end
end
