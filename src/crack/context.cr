module Crack
  class Context
    getter request : Request
    getter response : Response

    def initialize(@request, @response)
    end
  end
end
