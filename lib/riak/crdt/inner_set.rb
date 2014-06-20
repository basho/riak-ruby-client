module Riak
  module Crdt
    # The {InnerSet} is similar to a {Riak::Crdt::Set}, except it is part of
    # a {Map} (or an {InnerMap} inside of a {Map}). It is usually accessed
    # through a {TypedCollection}.
    #
    # Just like a {Riak::Crdt::Set}, it's a set of {String Strings} that can 
    # be added to or removed from.
    class InnerSet
      # The name of this set inside a map.
      #
      # @api private
      attr_accessor :name
      
      # The {::Set} value of this {InnerSet}.
      #
      # @return [::Set] set value
      attr_reader :value
      alias :members :value

      # The parent of this counter.
      #
      # @api private
      attr_reader :parent

      # @api private
      def initialize(parent, value=[])
        @parent = parent
        frozen_value = value.to_a.tap{ |v| v.each(&:freeze) }
        @value = ::Set.new frozen_value
        @value.freeze
      end
      
      # Casts this {InnerSet} to an {Array}.
      #
      # @return [Array] an array of all the members of this set
      def to_a
        value.to_a
      end

      # Check if this {InnerSet} is empty.
      #
      # @return [Boolean} whether this structure is empty or not
      def empty?
        value.empty?
      end

      # Check if a given string is in this structure.
      #
      # @param [String] element candidate string to check for inclusion
      # @return [Boolean] whether the candidate is in this set or not
      def include?(element)
        value.include? element
      end

      # Add a {String} to the {InnerSet}
      #
      # @param [String] element the element to add
      def add(element)
        @parent.operate name, update(add: element)
      end

      # Remove a {String} from this set
      #
      # @param [String] element the element to remove
      def remove(element)
        @parent.operate name, update(remove: element)
      end

      # @api private
      def update(changes)
        Operation::Update.new.tap do |op|
          op.value = changes.symbolize_keys
          op.type = :set
        end
      end

      # @api private
      def self.delete
        Operation::Delete.new.tap do |op|
          op.type = :set
        end
      end
    end
  end
end
