require 'spec_helper'
require 'rack/test'
require 'penguin'

describe Penguin do
  include Rack::Test::Methods

  let(:app) {
    Rack::Lint.new(
      Penguin::Middleware.new(
        lambda { |env| ['200', {'Content-Type' => 'text/html'}, ["Hey!\n"]] },
        {limit: 50})
    )
  }

  before(:each) { get '/' }

  it 'gets successful response' do
    expect(last_response.ok?).to be true
    expect(last_response).to include('X-RateLimit-Limit')
  end

  it 'sets limit rate from parameters' do
    expect(last_response.header['X-RateLimit-Limit']).to eq('50')
  end
end
