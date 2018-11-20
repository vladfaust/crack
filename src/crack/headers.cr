module Crack
  # From https://greenbytes.de/tech/webdav/rfc2616.html#rfc.section.4.2:
  #
  # "Multiple message-header fields with the same field-name may be present in a message if and only if the entire field-value for that header field is defined as a comma-separated list..."
  #
  # To simplify the code, Crack assumes that there are no headers with multiple names in the request.
  class Headers
    @hash = Hash(String, String).new

    def [](key : String)
      @hash[key.downcase]
    end

    def []?(key : String)
      @hash[key.downcase]?
    end

    def []=(key : String, value : String)
      value.each_byte do |byte|
        char = byte.unsafe_chr
        raise InvalidCharError.new unless valid_char?(char)
      end

      @hash[key.downcase] = value
    end

    forward_missing_to @hash

    protected def valid_char?(char)
      # According to RFC 7230, characters accepted as HTTP header
      # are '\t', ' ', all US-ASCII printable characters and
      # range from '\x80' to '\xff' (but the last is obsoleted.)
      return true if char == '\t'

      if char < ' ' || char > '\u{ff}' || char == '\u{7f}'
        return false
      end

      true
    end

    class InvalidCharError < Exception
    end
  end
end
