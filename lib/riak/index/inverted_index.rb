class InvertedIndex

  attr_accessor :bucket, :client, :bucket_name

  def initialize(client, bucket_name)
    self.client = client
    self.bucket_name = "#{bucket_name}"
    self.bucket = client.bucket(self.bucket_name)
    if !self.bucket.allow_mult
      self.bucket.allow_mult = true
    end
  end

  def put_index(index_name, key)
    index = GSet.new
    index.add(key)

    object = self.bucket.new(index_name)
    object.content_type = 'text/plain'
    object.data = index.to_json

    object.store(options={:returnbody => false})
  end

  def get_index(index_name)
    index_obj = self.bucket.get_or_new(index_name)

    index = GSet.new

    # If resolving siblings...
    if index_obj.siblings.length > 1
      index_obj.siblings.each { | obj |
        if !obj.data.nil?
          index.merge_json obj.data
        end
      }

      resolved_obj = self.bucket.new(index_name)
      resolved_obj.vclock = index_obj.vclock

      # previous content type was mulitpart/mixed, reset to something more innocuous
      resolved_obj.content_type = 'text/plain'
      resolved_obj.data = index.to_json
      resolved_obj.store(options={:returnbody => false})
    elsif !index_object.data.nil?
      index.merge_json(index_obj.data)
    end

    return index
  end

end