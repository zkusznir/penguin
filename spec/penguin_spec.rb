require 'spec_helper'
require 'rack/test'
require 'pry'

describe Penguin do
  include Rack::Test::Methods

  def app
    lambda { |env| ['200', {'Content-Type' => 'text/html'}, ["Hey there!\n"]] }
  end

  it 'gets successful response' do
    app
    get '/'
    expect last_response.ok?
  end
end
