module Penguin
  class Store
    def initialize
      @clients = {}
    end

    def get(key)
      @clients[key].dup
    end

    def set(key, value)
      @clients[key] = value
      @clients[key].dup
    end
  end
end
