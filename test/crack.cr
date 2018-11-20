require "../src/crack"

struct Foo
  include Crack::Middleware

  def call(context)
    context.response.body << "Hello Foo!\n"
    yield
  end
end

class Bar
  include Crack::Middleware

  def initialize(@bar : String)
  end

  def call(context, &block)
    context.response.headers["Bar"] = @bar
    context.response.body << "Hello #{@bar}!\n"
    yield
  end
end

server = Crack::Server.new([Foo.new, Bar.new("Baz")])
server.bind_tcp("0.0.0.0", 5000, reuse_port: true)

puts "\nListening"
server.listen
