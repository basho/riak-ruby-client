module Riak
  module Crdt
    class Set < Base
      
      def initialize(bucket, key, bucket_type=nil, options={})
        super(bucket, key, bucket_type || DEFAULT_BUCKET_TYPES[:set], options)
      end

      def vivify(value)
        value.each(&:freeze)
        @members = Set.new(value)
        @members.freeze
      end

      def batch
        batcher = BatchSet.new self

        yield batcher
        
        operate batcher.operations
      end

      def members
        reload if dirty?
        @members
      end

      alias :value :members

      def to_a
        members.to_a
      end

      def empty?
        members.empty?
      end
      
      def include?(candidate)
        members.include?(candidate)
      end

      def add(element, options={})
        operate operation(:add, element), options
      end

      def remove(element, options={})
        operate operation(:remove, element), options
      end

      alias :delete :remove
      
      private
      def operation(direction, element)
        Operation::Update.new.tap do |op|
          op.type = :set
          op.value = { direction => element }
        end
      end

      class BatchSet
        def initialize(base)
          @base = base
          @adds = ::Set.new
          @removes = ::Set.new
        end
        
        def add(element)
          @adds.add element
          @removes.delete element
        end

        def remove(element)
          @removes.add element
          @adds.delete element
        end

        alias :delete :remove

        def include?(element)
          members.include? element
        end

        def empty?
          members.empty?
        end

        def to_a
          members.to_a
        end

        def members
          (@base + @adds).subtract @removes
        end

        alias :value :members

        def operations
          Operation::Update.new.tap do |op|
            op.type = :set
            op.value = {add: @adds.to_a, remove: @removes.to_a}
          end
        end
      end
    end
  end
end
