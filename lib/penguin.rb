require "penguin/version"
require 'pry'

module Penguin
  class Middleware
    
    def initialize(app, options = {})
      @app = app
      @limit = @limit_remaining = options[:limit]
      @reset_in = options[:reset_in]
    end

    def call(env)
      @reset_at ||= Time.now + @reset_in
      @limit_remaning ||= @limit
      @limit_remaining = @limit if time_limit_elapsed
      return request_limit_exceeded if @limit_remaining == 0
      @limit_remaining -= 1
      @app.call(env).tap do |status, headers, body|
        headers['X-RateLimit-Limit'] = @limit.to_s
        headers['X-RateLimit-Remaining'] = @limit_remaining.to_s
        headers['X-RateLimit-Reset'] = @reset.to_s
      end
    end

    def request_limit_exceeded
      ['429', {'Content-Type' => 'text/html'}, ["Too many requests!\n"]]
    end

    def time_limit_elapsed
      Time.now - @reset_at >= 0
    end
  end
end
