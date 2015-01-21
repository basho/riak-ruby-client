class Riak::Client::BeefcakeProtobuffsBackend
  def bucket_properties_operator
    BucketPropertiesOperator.new(self)
  end


  class BucketPropertiesOperator
    attr_reader :backend

    QUORUMS = Riak::Client::ProtobuffsBackend::QUORUMS

    def initialize(backend)
      @backend = backend
    end

    def get(bucket, options={})
      response = backend.protocol do |p|
        p.write :GetBucketReq, get_request(bucket, options)
        p.expect :GetBucketResp, RpbGetBucketResp
      end

      properties = response.props.to_hash.stringify_keys

      return rubyfy(properties)
    end

    def put(bucket, props={}, options={})
      properties = riakify props

      request = put_request bucket, properties, options
      
      backend.protocol do |p|
        p.write :SetBucketReq, request
        p.expect :SetBucketResp
      end
    end

    private
    def rubyfy(received_properties)
      props = received_properties.dup

      rubyfy_quorums(props)
      rubyfy_hooks(props)

      return props
    end

    def riakify(requested_properties)
      props = requested_properties.stringify_keys

      riakify_quorums(props)

      return props
    end

    def rubyfy_quorums(props)
      %w{r pr w pw dw rw}.each do |k|
        next unless props[k]
        next unless QUORUMS.values.include? props[k]

        props[k] = QUORUMS.invert[props[k]]
      end
    end

    def riakify_quorums(props)
      %w{r pr w pw dw rw}.each do |k|
        next unless props[k]
        v = props[k].to_s
        next unless QUORUMS.keys.include? v

        props[k] = QUORUMS[v]
      end
    end

    def rubyfy_hooks(props)
    end

    def name_options(bucket)
      o = {}
      if bucket.is_a? Riak::Bucket
        o[:bucket] = bucket.name 
        o[:type] = bucket.type.name if bucket.needs_type?
      else
        o[:bucket] = bucket
      end
      
      return o
    end

    def get_request(bucket, options)
      RpbGetBucketReq.new options.merge name_options(bucket)
    end

    def put_request(bucket, props, options)
      req_options = options.merge name_options(bucket)
      req_options[:props] = RpbBucketProps.new props.symbolize_keys

      RpbSetBucketReq.new req_options
    end
  end
end
