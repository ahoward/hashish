class Array
  def to_hashish(*args, &block)
    Hashish.to_hashish(self, *args, &block)
  end
end
