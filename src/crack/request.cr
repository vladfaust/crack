module Crack
  class Request
    getter method : String
    getter resource : String
    getter version : String
    getter headers : Headers
    getter body : IO?

    def uri : URI
      @uri ||= URI.parse(@resource)
    end

    @uri : URI?

    def initialize(@method, @resource, @version, @headers, @body)
    end

    def self.new(io : IO)
      # now = Time.monotonic

      request_line? = io.gets(4096, chomp: true)
      return empty_request_error unless request_line?
      request_line = request_line?.not_nil!

      # puts "request_line    took #{Time.monotonic - now}"
      # now = Time.monotonic

      parts = request_line.split
      return bad_request_error unless parts.size == 3
      return bad_request_error unless SUPPORTED_HTTP_VERSIONS.includes?(parts[2])

      # puts "reading parts   took #{Time.monotonic - now}"
      # now = Time.monotonic

      method, resource, version = parts
      headers = Headers.new
      body = nil

      headers_size = 0
      while line = io.gets(16_384, chomp: true)
        headers_size += line.bytesize
        break if headers_size > 16_384

        if line.empty?
          if content_length = headers["content-length"]?.try &.to_i
            if content_length > 0
              body = IO::Sized.new(io, content_length)
            end
          end

          if body
            {% if flag?(:without_zlib) %}
              raise "Can't decompress request body because `-D without_zlib` was passed at compile time"
            {% else %}
              case headers["content-encoding"]?
              when "gzip"
                body = Gzip::Reader.new(body.not_nil!, true)
              when "deflate"
                body = Flate::Reader.new(body.not_nil!, true)
              end
            {% end %}

            encoding = headers["content-type"]?.try do |header|
              header.split(';', 2, remove_empty: true).[1]?.try(&.strip)
            end

            if encoding
              body.set_encoding(encoding, invalid: :skip)
            end
          end

          break
        end

        name, value = line.split(':', 2)
        headers[name] = value
      end

      # puts "headers + body  took #{Time.monotonic - now}"

      return new(method, resource, version, headers, body)
    end

    protected class_getter bad_request_error = BadRequestError.new
    protected class_getter empty_request_error = EmptyRequestError.new

    class BadRequestError < Exception
    end

    class EmptyRequestError < Exception
    end
  end
end
