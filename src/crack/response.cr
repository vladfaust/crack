require "http/common"

module Crack
  class Response
    property io : IO
    property middleware : Array(Middleware)
    property version : String
    property status = 200
    property body : IO = IO::Memory.new
    property headers = Headers.new
    getter? upgraded = false

    def initialize(@io, @middleware, @version = "HTTP/1.1")
    end

    def write
      if body.is_a?(IO::Memory)
        @headers["Content-Length"] = body.as(IO::Memory).size.to_s
      end

      write_before_body
      @io << "\r\n" << body
      @io.flush
    end

    def write_default_response(@status)
      @body << "#{@status} #{HTTP.default_status_message_for(@status)}"
      write
    end

    def upgrade
      @upgraded = true
      write_before_body
      @io.flush
      yield @io
    end

    protected def write_before_body
      status_message = HTTP.default_status_message_for(@status)

      @io << @version << ' ' << @status << ' ' << status_message << "\r\n"

      headers.each do |name, value|
        @io << name << ": " << value << "\r\n"
      end
    end
  end
end
