require "penguin/version"

module Penguin
  class Middleware
    attr_accessor :app
    
    def initialize(app, options = {})
      @app = app
      @limit = options[:limit]
    end

    def call(env)
      status, headers, body = @app.call(env)
      headers['X-RateLimit-Limit'] = @limit
      [status, headers, body]
    end
  end
end
