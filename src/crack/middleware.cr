module Crack
  module Middleware
    abstract def call(context, &block)
  end
end
