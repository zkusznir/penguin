require "penguin/version"

module Penguin
  class Middleware
    
    def initialize(app, options = {})
      @app = app
      @limit = options[:limit]
    end

    def call(env)
      status, headers, body = @app.call(env)
      @limit_remaining ||= @limit
      @limit_remaining -= 1
      headers['X-RateLimit-Limit'] = @limit.to_s
      headers['X-RateLimit-Remaining'] = @limit_remaining.to_s
      [status, headers, body]
    end
  end
end
