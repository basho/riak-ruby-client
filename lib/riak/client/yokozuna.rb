module Riak
  class Client
    def create_search_index(name, schema=nil, n_val=nil)
      raise ArgumentError, t("zero_length_index") if name.nil? || name.empty?
      backend do |b|
        b.create_search_index(name, schema, n_val)
      end
      true
    end

    def get_search_index(name)
      raise ArgumentError, t("zero_length_index") if name.nil? || name.empty?
      resp = []
      backend do |b|
        resp = b.get_search_index(name)
      end
      resp.index && Array === resp.index ? resp.index.first : resp
    end

    def list_search_indexes()
      resp = []
      backend do |b|
        resp = b.get_search_index(nil)
      end
      resp.index ? resp.index : resp
    end

    def delete_search_index(name)
      raise ArgumentError, t("zero_length_index") if name.nil? || name.empty?
      backend do |b|
        b.delete_search_index(name)
      end
      true
    end

    def create_search_schema(name, content)
      raise ArgumentError, t("zero_length_schema") if name.nil? || name.empty?
      raise ArgumentError, t("zero_length_content") if content.nil? || content.empty?
      backend do |b|
        b.create_search_schema(name, content)
      end
      true
    end

    def get_search_schema(name)
      raise ArgumentError, t("zero_length_schema") if name.nil? || name.empty?
      backend do |b|
        return b.get_search_schema(name)
      end
    end
  end
end