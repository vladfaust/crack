# Сrack

Alternative HTTP::Server implementation, inspired by Rack

## Why

Because it's fun! And also because I feel some features are missing or implemented slightly wrong in the default server. Crack differs in following ways:

### Middleware

Instead of `HTTP::Handler` with cumbersome `call_next(context)` there is an alternative approach with `yield`ing:

```crystal
struct SimpleMiddleware
  include Crack::Middleware

  def call(context, &block) # `&block` can be ommited if there is `yield` within the def body
    context.response.body << "Hello World!\n"
    yield # Calls the next middleware in the stack
  end
end
```

Internally it's processed like this:

```crystal
protected def process(context, middleware = context.response.middleware, index = 0)
  middleware[index].call(context) do
    if context.response.middleware[index + 1]?
      process(context, context.response.middleware, index + 1)
    end
  end
end
```

As you can see, the middleware is **dynamic** and can be changed *after* the server is initialized and even on a separate response level! Hello, [Amber pipelines](https://docs.amberframework.org/amber/guides/routing/pipelines)! 👋

Also the server initializer doesn't take accept proc argument anymore.

### Writing to response

A response has its own body IO, which will be written to the actual response IO only after running through all the middleware. This allows to write the status code and headers in the very end of processing.

## Installation

1. Add the dependency to your `shard.yml`:

```yaml
dependencies:
  crack:
    github: vladfaust/crack
```

2. Run `shards install`

## Usage

```crystal
require "crack"

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
    context.headers["Bar"] = @bar
    context.response.body << "Hello, #{@bar}!\n"
    yield
  end
end

server = Crack::Server.new([Foo.new, Bar.new("Baz")])
server.bind_tcp("0.0.0.0", 5000, reuse_port: true)

puts "\nListening"
server.run
```

## Development

TODO: Write development instructions here

## Contributing

1. Fork it (<https://github.com/vladfaust/crack/fork>)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## Contributors

- [@vladfaust](https://github.com/vladfaust) - creator and maintainer
