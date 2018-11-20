require "socket"
require "http/request"
require "http/server"

def handle_client(io)
  must_close = true
  response = HTTP::Server::Response.new(io)

  begin
    loop do
      if io.is_a?(IO::Buffered)
        io.sync = false
      end

      request = HTTP::Request.from_io(io)
      break unless request

      if request.is_a?(HTTP::Request::BadRequest)
        response.respond_with_error("Bad Request", 400)
        response.close
        return
      end

      response.version = request.version
      response.reset

      response.output.print("Hello World!\n")
      response.output.close
      io.flush

      request.body.try &.close
    rescue ex : Errno
      # IO-related error, nothing to do
    ensure
      begin
        io.close if must_close
      rescue ex : Errno
        # IO-related error, nothing to do
      end
    end
  end
end

server = TCPServer.new("localhost", 5000, reuse_port: true)
puts "\nListening"
loop do
  io = server.accept?

  if io
    _io = io
    spawn handle_client(_io)
  end
end
