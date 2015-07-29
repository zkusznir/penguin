require "penguin/version"

module Penguin
  class Middleware
    
    def initialize(app, options = {})
      @app = app
      @limit = options[:limit]
    end

    def call(env)
      @limit_remaining ||= @limit
      return limit_exceeded if @limit_remaining == 0
      @limit_remaining -= 1
      @app.call(env).tap do |status, headers, body|
        headers['X-RateLimit-Limit'] = @limit.to_s
        headers['X-RateLimit-Remaining'] = @limit_remaining.to_s
      end
    end

    def limit_exceeded
      ['429', {'Content-Type' => 'text/html'}, ["Too many requests!\n"]]
    end
  end
end
