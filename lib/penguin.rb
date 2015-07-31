require "penguin/version"

module Penguin
  class Middleware
    
    def initialize(app, options = {})
      @clients = {}
      @app, @limit, @reset_in = app, options[:limit], options[:reset_in]
    end

    def call(env)
      client = env['REMOTE_ADDR']
      new_client?(client)
      time_limit_elapsed?(client)
      return request_limit_exceeded if @clients[client][:limit_remaining] == 0
      @clients[client][:limit_remaining] -= 1
      @app.call(env).tap do |status, headers, body|
        headers['X-RateLimit-Limit'] = @limit.to_s
        headers['X-RateLimit-Remaining'] = @clients[client][:limit_remaining].to_s
        headers['X-RateLimit-Reset'] = @clients[client][:reset_at].to_i.to_s
      end
    end

    def request_limit_exceeded
      ['429', {'Content-Type' => 'text/html'}, ["Too many requests!\n"]]
    end

    def new_client?(client)
      @clients[client] ||= {limit_remaining: @limit, reset_at: Time.now + @reset_in}
    end

    def time_limit_elapsed?(client)
      if Time.now - @clients[client][:reset_at] >= 0
        @clients[client][:reset_at] = Time.now + @reset_in
        @clients[client][:limit_remaining] = @limit
      end
    end
  end
end
