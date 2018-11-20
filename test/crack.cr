require "../src/crack"

struct SimpleMiddleware
  include Crack::Middleware

  def call(context, &block)
    context.response.body << "Hello World!\n"
  end
end

server = Crack::Server.new([SimpleMiddleware.new])
server.bind_tcp("0.0.0.0", 5000)
puts "\nListening"
server.run
