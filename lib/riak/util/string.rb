module Riak
  module Util
    # Methods comparing strings
    module String
      def equal_bytes?(a, b)
        return true if a.nil? && b.nil?

        return false unless a.respond_to?(:bytesize)
        return false unless b.respond_to?(:bytesize)
        return false unless a.bytesize == b.bytesize

        return false unless a.respond_to?(:bytes)
        return false unless b.respond_to?(:bytes)

        b1 = a.bytes.to_a
        b2 = b.bytes.to_a
        i = 0
        loop do
          c1 = b1[i]
          c2 = b2[i]
          return false unless c1 == c2
          i += 1
          break if i > b1.length
        end
        true
      end

      module_function :equal_bytes?
    end
  end
end
