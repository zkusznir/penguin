require 'spec_helper'
require 'rack/test'
require 'penguin'
require 'timecop'

describe Penguin do
  include Rack::Test::Methods

  let(:rack_app) { lambda { |env| ['200', {'Content-Type' => 'text/html'}, ["Hey!\n"]] } }
  let(:app) { Rack::Lint.new(Penguin::Middleware.new(rack_app, { limit: 20, reset_in: 3600 })) }

  context 'when limit is set' do
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
  end

  context 'when limit exceeded' do
    before(:each) { 20.times { get '/' } }

    it 'prevents access' do
      expect(rack_app).not_to receive(:call)
      get '/'
    end

    it 'returns 429 status' do
      get '/'
      expect(last_response.status).to eq(429)
    end
  end

  it 'resets limit after specified time' do
    10.times { get '/' }
    expect(last_response.header['X-RateLimit-Remaining'].to_i).to eq(10)
    Timecop.freeze(Time.now + 4000) do
      get '/'
      expect(last_response.header['X-RateLimit-Remaining'].to_i).to eq(19)
    end
  end
end
