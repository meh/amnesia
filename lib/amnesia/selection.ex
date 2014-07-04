defprotocol Amnesia.Selection do
  def coerce(self, module)
  def next(self)
  def values(self)
end

defimpl Amnesia.Selection, for: Atom do
  def coerce(nil, _) do
    nil
  end

  def next(nil) do
    nil
  end

  def values(nil) do
    []
  end
end
