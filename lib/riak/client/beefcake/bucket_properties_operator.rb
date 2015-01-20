class Riak::Client::BeefcakeProtobuffsBackend
  def bucket_properties_operator
    BucketPropertiesOperator.new(self)
  end


  class BucketPropertiesOperator
    def initialize(backend)
      @backend = backend
    end
  end
end
