
class Symbol
  include Comparable
  def <=>(other)
    self.to_s <=> other.to_s
  end
end


class BSON::ObjectId
  include Comparable
  def <=>(other)
    self.to_s <=> other.to_s
  end
end
