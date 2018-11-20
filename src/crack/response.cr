require "http/common"

module Crack
  class Response
    property status = 200
    property body : IO = IO::Memory.new
    property headers = Headers.new
    property version : String

    def initialize(@version)
    end

    def write(io : IO)
      status_message = HTTP.default_status_message_for(@status)

      io << @version << ' ' << @status << ' ' << status_message << "\r\n"

      headers.each do |name, value|
        io << name << ": " << value << "\r\n"
      end

      io << "\r\n" << body
    end
  end
end
