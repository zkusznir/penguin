module Penguin
  class Store
    def initialize
      @clients = {}
    end

    def get(key)
      @clients[key].dup if @clients[key]
    end

    def set(key, value)
      @clients[key] = value
    end
  end
end
