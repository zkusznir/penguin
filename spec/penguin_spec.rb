require 'spec_helper'
require 'rack/test'
require 'penguin'

describe Penguin do
  include Rack::Test::Methods

  let(:limit) { 50 }

  let(:app) {
    Rack::Lint.new(
      Penguin::Middleware.new(
        lambda { |env| ['200', {'Content-Type' => 'text/html'}, ["Hey!\n"]] },
        {limit: limit})
    )
  }

  before(:each) { get '/' }

  it 'gets successful response' do
    expect(last_response).to be_ok
  end

  it 'sets limit rate from parameters' do
    expect(last_response.header['X-RateLimit-Limit']).to eq(limit.to_s)
  end

  it 'decreases limit rate' do
    expect(last_response.header['X-RateLimit-Remaining'].to_i).to eq(limit-1)
    get '/'
    expect(last_response.header['X-RateLimit-Remaining'].to_i).to eq(limit-2)
  end
end
