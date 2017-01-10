# Copyright 2010-present Basho Technologies, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

require 'zlib'
require 'stringio'

module Riak
  module Util
    # Borrowed from ActiveSupport
    # https://github.com/rails/rails/blob/master/activesupport/lib/active_support/gzip.rb
    #
    # A convenient wrapper for the zlib standard library that allows
    # compression/decompression of strings with gzip.
    #
    #   gzip = Riak::Util::Gzip.compress('compress me!')
    #   # => "\x1F\x8B\b\x00o\x8D\xCDO\x00\x03K\xCE\xCF-(J-.V\xC8MU\x04\x00R>n\x83\f\x00\x00\x00"
    #
    #   Riak::Util::Gzip.decompress(gzip)
    #   # => "compress me!"
    module Gzip
      class Stream < StringIO
        def initialize(*)
          super
          set_encoding "BINARY"
        end

        def close
          rewind
        end
      end

      # Decompresses a gzipped string.
      def self.decompress(source)
        Zlib::GzipReader.new(StringIO.new(source)).read
      end

      # Compresses a string using gzip.
      def self.compress(source, level = Zlib::DEFAULT_COMPRESSION, strategy = Zlib::DEFAULT_STRATEGY)
        output = Stream.new
        gz = Zlib::GzipWriter.new(output, level, strategy)
        gz.write(source)
        gz.close
        output.string
      end
    end
  end
end
