class InvertedIndex

  attr_accessor :bucket, :client, :bucket_name

  def initialize(client, bucket_name)
    self.client = client
    self.bucket_name = "#{bucket_name}_inverted_indices"
    self.bucket = client.bucket(self.bucket_name)
    self.bucket.allow_mult = true
  end

  def put_index(index_name, key)
    index = GSet.new
    index.add(key)

    object = self.bucket.new(index_name)
    object.content_type = 'text/plain'
    #object.data = index.to_json
    object.raw_data = index.to_marshal

    object.store
  end

  def get_index(index_name)
    index_obj = self.bucket.get_or_new(index_name)

    index = GSet.new

    index_obj.siblings.each { | obj |
      if !obj.raw_data.nil?
        index.merge_marshal obj.raw_data
      end
      #if !obj.data.nil?
      #  index.merge_json obj.data
      #end
    }

    # If resolving siblings...
    if index_obj.siblings.length > 1
      # previous content type was mulitpart/mixed, reset to something more innocuous
      index_obj.content_type = 'text/plain'
      index_obj.raw_data = index.to_marshal
      #index_obj.data = index.to_json
      index_obj.store
    end

    return index
  end

end