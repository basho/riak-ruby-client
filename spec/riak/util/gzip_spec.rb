require 'spec_helper'

# Borrowed from ActiveSupport
# https://github.com/rails/rails/blob/master/activesupport/test/gzip_test.rb

describe Riak::Util::Gzip do
  describe ".compress" do
    it "decompresses to the same value" do
      expect(Riak::Util::Gzip.decompress(Riak::Util::Gzip.compress("Hello World"))).to eq("Hello World")
      expect(Riak::Util::Gzip.decompress(Riak::Util::Gzip.compress("Hello World", Zlib::NO_COMPRESSION))).to eq("Hello World")
      expect(Riak::Util::Gzip.decompress(Riak::Util::Gzip.compress("Hello World", Zlib::BEST_SPEED))).to eq("Hello World")
      expect(Riak::Util::Gzip.decompress(Riak::Util::Gzip.compress("Hello World", Zlib::BEST_COMPRESSION))).to eq("Hello World")
      expect(Riak::Util::Gzip.decompress(Riak::Util::Gzip.compress("Hello World", nil, Zlib::FILTERED))).to eq("Hello World")
      expect(Riak::Util::Gzip.decompress(Riak::Util::Gzip.compress("Hello World", nil, Zlib::HUFFMAN_ONLY))).to eq("Hello World")
      expect(Riak::Util::Gzip.decompress(Riak::Util::Gzip.compress("Hello World", nil, nil))).to eq("Hello World")
    end

    it "returns a binary string" do
      compressed = Riak::Util::Gzip.compress('')

      expect(compressed.encoding).to eq(Encoding.find('binary'))
      expect(compressed).not_to be_blank
    end

    it "returns gzipped string by compression level" do
      source_string = "Hello World"*100

      gzipped_by_speed = Riak::Util::Gzip.compress(source_string, Zlib::BEST_SPEED)
      expected_level = if RUBY_PLATFORM == 'java'
                         # NB HACK: on jruby, level is -1
                         -1
                       else
                         Zlib::BEST_SPEED
                       end
      expect(Zlib::GzipReader.new(StringIO.new(gzipped_by_speed)).level).to eq(expected_level)

      gzipped_by_best_compression = Riak::Util::Gzip.compress(source_string, Zlib::BEST_COMPRESSION)
      expected_level = if RUBY_PLATFORM == 'java'
                         # NB HACK: on jruby, level is -1
                         -1
                       else
                         Zlib::BEST_COMPRESSION
                       end
      expect(Zlib::GzipReader.new(StringIO.new(gzipped_by_best_compression)).level).to eq(expected_level)

      expect(gzipped_by_best_compression.bytesize < gzipped_by_speed.bytesize).to be true
    end
  end
end
