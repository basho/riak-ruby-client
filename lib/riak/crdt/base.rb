module Riak
  module Crdt
    # Basic and shared code used by the top-level CRDTs. In particular, dirty-
    # tracking, loading, and operating is implemented by this class, and
    # the {Riak::Crdt::Set}, {Riak::Crdt::Counter}, and {Riak::Crdt::Map}
    # classes implement everything else.
    #
    # @api private
    class Base
      include Util::Translation
      attr_reader :bucket
      attr_reader :bucket_type

      # Returns the key of this CRDT. Extremely useful when using a
      # Riak-assigned key.
      attr_reader :key

      # Base CRDT initialization The bucket type is determined by the first of
      # these sources:
      #
      # 1. The `bucket_type` String argument
      # 2. A {BucketTyped::Bucket} as the `bucket` argument
      # 3. A `bucket_type` Symbol argument is looked up in the
      #    `Crdt::Base::DEFAULT_BUCKET_TYPES` hash
      # @api private
      #
      # @param [Bucket] bucket the {Riak::Bucket} for this counter
      # @param [String, nil] key The name of the counter. A nil key makes
      #        Riak assign a key.
      # @param [String] bucket_type The optional bucket type for this counter.
      #        The default is in `Crdt::Base::DEFAULT_BUCKET_TYPES[:counter]`.
      # @param [Hash] options
      def initialize(bucket, key, bucket_type, options = {})
        configure_bucket bucket
        configure_key key
        configure_bucket_type bucket_type
        @options = options

        @dirty = true
      end

      def dirty?
        @dirty
      end

      # Force a reload of this structure from Riak.
      def reload
        loader do |l|
          vivify l.load @bucket, @key, @bucket_type
          @context = l.context
        end
        @dirty = false

        self
      end

      # Does this CRDT have the context necessary to remove elements?
      #
      # @return [Boolean] if the set has a defined context
      def context?
        !!@context
      end

      def ==(other)
        return false unless other.is_a? Riak::Crdt::Base
        return false unless self.bucket_type == other.bucket_type
        return false unless self.bucket == other.bucket
        return false unless self.key == other.key
        return true
      end

      def pretty_print(pp)
        pp.object_group self do
          pp.breakable
          pp.text "bucket_type=#{@bucket_type}"
          pp.comma_breakable
          pp.text "bucket=#{@bucket.name}"
          pp.comma_breakable
          pp.text "key=#{@key}"

          yield
        end
      end

      def pretty_print_cycle(pp)
        pp.object_group self do
          pp.breakable
          pp.text "#{@bucket_type}/#{@bucket.name}/#{@key}"
        end
      end

      def inspect_name
        "#<#{self.class.name} bucket=#{@bucket.name} " \
        "key=#{@key} type=#{@bucket_type}>"
      end

      private

      def client
        @bucket.client
      end

      def backend(&blk)
        client.backend(&blk)
      end

      def loader
        backend do |be|
          yield be.crdt_loader
        end
      end

      def operator
        backend do |be|
          yield be.crdt_operator
        end
      end

      def operate(*args)
        options = {}
        options = args.pop if args.last.is_a? Hash
        options[:context] ||= @context
        result = operator do |op|
          response = op.operate(bucket.name,
                                key,
                                bucket_type,
                                *args,
                                options
                                )

          break if :empty == response
          @key = response.key if response.key
          response
        end

        @dirty = true
        vivify_returnbody(result)

        true
      end

      def vivify_returnbody(result)
        loader do |l|
          specific_loader = l.get_loader_for_value result

          return false if specific_loader.nil?

          vivify specific_loader.rubyfy
          @context = result.context unless result.context.nil?
          @dirty = false
        end
      end

      def configure_bucket_type(constructor_type)
        @bucket_type = if constructor_type.is_a? String
                         constructor_type
                       elsif constructor_type.is_a? BucketType
                         constructor_type.name
                       elsif @bucket.is_a? BucketTyped::Bucket
                         @bucket.type.name
                       elsif constructor_type.is_a? Symbol
                         DEFAULT_BUCKET_TYPES[constructor_type]
                       end
      end

      def configure_bucket(bucket)
        unless bucket.is_a? Bucket
          fail ArgumentError, t('bucket_type', bucket: bucket.inspect)
        end

        @bucket = bucket
      end

      def configure_key(key)
        unless key.is_a?(String) || key.nil?
          fail ArgumentError, t('string_type', string: key.inspect)
        end

        @key = key
      end
    end
  end
end
