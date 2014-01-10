module Riak
  module Crdt
    class InnerSet
      attr_accessor :name
      
      attr_reader :value
      alias :members :value
      
      def initialize(parent, value=[])
        @parent = parent
        value.each(&:freeze)
        @value = ::Set.new value.to_a
        @value.freeze
      end

      def to_a
        value.to_a
      end

      def empty?
        value.empty?
      end

      def include?(element)
        value.include? element
      end

      def add(element)
        @parent.operate name, update(add: element)
      end

      def remove(element)
        @parent.operate name, update(remove: element)
      end

      def update(changes)
        Operation::Update.new.tap do |op|
          op.value = changes.symbolize_keys
          op.type = :set
        end
      end
    end
  end
end
