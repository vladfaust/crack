# require "deque"

module Crack
  class Server
    property middleware : Array(Middleware)
    getter sockets = Array(Socket::Server).new

    getter? closed = false
    getter? listening = false

    def initialize(middleware)
      @middleware = middleware.map(&.as(Middleware))
    end

    def bind_tcp(host : String, port : Int32, reuse_port : Bool = false)
      bind(TCPServer.new(host, port, reuse_port: reuse_port))
    end

    def bind(socket : Socket::Server) : Nil
      raise "Can't add socket to a running server" if listening?
      raise "Can't add socket to a closed server" if closed?

      @sockets << socket
    end

    def listen
      raise "Can't restart a closed server" if closed?
      raise "Can't start a server with no sockets to listen to" if @sockets.empty?
      raise "Can't start an already running server" if listening?

      @listening = true
      done = Channel(Nil).new

      @sockets.each do |socket|
        spawn do
          until closed?
            io = begin
              socket.accept?
            rescue e
              e.inspect_with_backtrace(STDERR)
              STDERR.flush
              nil
            end

            if io.is_a?(IO::Buffered)
              io.sync = false
            end

            spawn handle_client(io.not_nil!) if io
          end
        ensure
          done.send(nil)
        end
      end

      @sockets.size.times { done.receive }
    end

    def close
      raise "Can't close an already closed server" if closed?
      @closed = true

      @sockets.each do |socket|
        socket.close
      rescue
        # Ignore exceptions on socket close
      end

      @listening = false
      @sockets.clear
    end

    protected def handle_client(io : IO)
      close? = true

      begin
        loop do
          request = Request.new(io)
          break unless request # EOF

          response = Response.new(io, @middleware, request.version)

          if request.is_a?(BadRequest)
            response.write_default_response(400)
            return
          end

          response.version = request.version
          response.headers["Connection"] = "keep-alive" if request.keep_alive?

          begin
            process(Context.new(request, response))
          rescue ex
            response.write_default_response(500)

            STDERR << "Unhandled exception on Crack::Server#process"
            ex.inspect_with_backtrace(STDERR)

            return
          end

          response.write
          io.flush

          if response.upgraded?
            close? = false
            return
          end

          break unless request.keep_alive?
        end
      rescue ex : Errno
      ensure
        begin
          io.close if close?
        rescue ex : Errno
        end
      end
    end

    protected def process(context : Context)
      process(context, context.response.middleware)
    end

    protected def process(context, middleware, index = 0)
      middleware[index].call(context) do
        process(context, context.response.middleware, index + 1) if context.response.middleware[index + 1]?
      end
    end
  end
end
