# require "deque"

module Crack
  class Server
    property middleware : Array(Middleware)
    getter sockets = Array(Socket::Server).new

    getter? closed = false
    getter? listening = false

    # @times_reading = Deque(Time::Span).new
    # @times_parsing_request = Deque(Time::Span).new
    # @times_processing = Deque(Time::Span).new
    # @times_writing = Deque(Time::Span).new

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

    def run
      raise "Can't restart a closed server" if closed?
      raise "Can't start a server with no sockets to listen to" if @sockets.empty?
      raise "Can't start an already running server" if listening?

      Signal::INT.trap do
        puts "\nClosing"

        # puts "Avg reading request:  #{@times_reading.to_a.reduce(Time::Span.zero) { |t, s| s += t } / @times_reading.size}"
        # puts "Avg parsing request:  #{@times_parsing_request.to_a.reduce(Time::Span.zero) { |t, s| s += t } / @times_parsing_request.size}"
        # puts "Avg processing:       #{@times_processing.to_a.reduce(Time::Span.zero) { |t, s| s += t } / @times_processing.size}"
        # puts "Avg writing response: #{@times_writing.to_a.reduce(Time::Span.zero) { |t, s| s += t } / @times_writing.size}"

        close
        exit
      end

      @listening = true
      done = Channel(Nil).new

      @sockets.each do |socket|
        spawn do
          until closed?
            # now = Time.monotonic

            io = begin
              socket.accept?
            rescue e
              e.inspect_with_backtrace STDERR
              STDERR.flush

              nil
            end

            # @times_reading << Time.monotonic - now

            if _io = io
              _io.as(IO::Buffered).sync = false
              spawn handle_client(_io)
            else
              break
            end
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
      # now = Time.monotonic

      request = Request.new(io)

      # @times_parsing_request << Time.monotonic - now
      # now = Time.monotonic

      if request.is_a?(Request)
        response = Response.new(request.version)
        process(Context.new(request, response))

        # @times_processing << Time.monotonic - now
        # now = Time.monotonic

        response.write(io)

        # @times_writing << Time.monotonic - now
      end
    ensure
      io.close
    end

    protected def process(context : Context)
      process(context, @middleware)
    end

    protected def process(context, middleware, index = 0)
      middleware[index].call(context) do
        process(context, middleware, index + 1) if middleware[index + 1]?
      end
    end
  end
end
