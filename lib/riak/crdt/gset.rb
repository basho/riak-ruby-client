require 'json'

class GSet
  attr_accessor :members

  def initialize
    self.members = Set.new
  end

  def merge(other)
    self.members.merge other.members
  end

  def add(atom)
    self.members.add atom
  end

  def include?(atom)
    self.members.include? atom
  end

  def to_json
    {
        type: 'GSet',
        a: self.members.to_a
    }.to_json
  end

  def array_from_json(json)
    h = JSON.parse json, symbolize_names: true
    raise ArgumentError.new 'unexpected field in JSON' unless h[:type] == 'GSet'

    return h[:a]
  end


  def from_json(json)
    gs = new

    gs.members.merge array_from_json(json)

    return gs
  end

  def merge_json(json)
    self.members.merge array_from_json(json)
  end

  def to_marshal
    Marshal.dump(self.members.to_a)
  end

  def from_marshal(marshaled)
    gs = new
    gs.members.merge Marshal.load(marshaled)

    return gs
  end

  def merge_marshal(marshaled)
    self.members.merge Marshal.load(marshaled)
  end
end