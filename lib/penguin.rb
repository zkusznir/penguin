require "penguin/version"

module Penguin
  class Middleware
    
    def initialize(app, options = {})
      @app = app
      @limit = @limit_remaining = options[:limit]
      @reset_in = options[:reset_in]
    end

    def call(env)
      check_if_time_limit_elapsed
      return request_limit_exceeded if @limit_remaining == 0
      @limit_remaining -= 1
      @app.call(env).tap do |status, headers, body|
        headers['X-RateLimit-Limit'] = @limit.to_s
        headers['X-RateLimit-Remaining'] = @limit_remaining.to_s
        headers['X-RateLimit-Reset'] = @reset_at.to_i.to_s
      end
    end

    def request_limit_exceeded
      ['429', {'Content-Type' => 'text/html'}, ["Too many requests!\n"]]
    end

    def check_if_time_limit_elapsed
      if @reset_at.nil? || Time.now - @reset_at >= 0
        @reset_at = Time.now + @reset_in
        @limit_remaining = @limit
      end
    end
  end
end
