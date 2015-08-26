require "penguin/version"
require 'store'

module Penguin
  class Middleware
    
    def initialize(app, options = {}, store = Penguin::Store.new, &block)
      @app, @store, @limit, @reset_in = app, store, options[:limit], options[:reset_in]
      @block = block
    end

    def call(env)
      client_id = @block.nil? ? env['REMOTE_ADDR'] : @block.call(env)
      puts client_id # use X_FORWARDED_FOR maybe
      return @app.call(env) if client_id.nil?
      client = get_or_create_client(client_id)
      reset_limit_if_time_limit_elapsed(client)
      return request_limit_exceeded if client[:limit_remaining] == 0
      client[:limit_remaining] -= 1
      @store.set(client_id, client)
      @app.call(env).tap do |status, headers, body|
        headers['X-RateLimit-Limit'] = @limit.to_s
        headers['X-RateLimit-Remaining'] = client[:limit_remaining].to_s
        headers['X-RateLimit-Reset'] = client[:reset_at].to_i.to_s
      end
    end

    def request_limit_exceeded
      ['429', {'Content-Type' => 'text/html'}, ["Too many requests!\n"]]
    end

    def get_or_create_client(client_id)
      if client = @store.get(client_id)
        client
      else
        @store.set(client_id, default_values)
        default_values
      end
    end

    def default_values
      {limit_remaining: @limit, reset_at: Time.now + @reset_in}
    end

    def reset_limit_if_time_limit_elapsed(client)
      if Time.now - client[:reset_at] >= 0
        client[:reset_at] = Time.now + @reset_in
        client[:limit_remaining] = @limit
      end
    end
  end
end
