require 'spec_helper'
require 'rack/test'
require 'penguin'

describe Penguin do
  include Rack::Test::Methods

  let(:middleware) {
    Penguin::Middleware.new(
      lambda { |env| ['200', {'Content-Type' => 'text/html'}, ["Hey!\n"]] },
      {limit: 20})
  }
  
  let(:app) { Rack::Lint.new(middleware) }

  before(:each) { get '/' }

  it 'gets successful response' do
    expect(last_response).to be_ok
  end

  it 'sets limit rate from parameters' do
    expect(last_response.header['X-RateLimit-Limit']).to eq('20')
  end

  it 'decreases limit rate' do
    expect(last_response.header['X-RateLimit-Remaining'].to_i).to eq(19)
    get '/'
    expect(last_response.header['X-RateLimit-Remaining'].to_i).to eq(18)
  end

  it 'prevents access when limit exceeded' do
    20.times { get '/' }
    expect(last_response.status).to eq(429)
  end
end
