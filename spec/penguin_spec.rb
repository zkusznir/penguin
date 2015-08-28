require 'spec_helper'
require 'rack/test'
require 'penguin'
require 'timecop'
require 'store'

describe Penguin do
  include Rack::Test::Methods

  let(:rack_app) { lambda { |env| ['200', {'Content-Type' => 'text/html'}, ["Hey!\n"]] } }
  let(:store) { Penguin::Store.new }
  let(:middleware) { Penguin::Middleware.new(rack_app, { limit: 20, reset_in: 3600 }, store) }
  let(:app) { Rack::Lint.new(middleware) }

  context 'when limit is set' do
    before(:each) { get '/', {}, 'HTTP_X_FORWARDED_FOR' => '10.0.0.1' }

    it 'gets successful response' do
      expect(last_response).to be_ok
    end

    it 'sets limit rate from parameters' do
      expect(last_response.header['X-RateLimit-Limit']).to eq('20')
    end

    it 'decreases limit rate' do
      expect(last_response.header['X-RateLimit-Remaining'].to_i).to eq(19)
      get '/', {}, 'HTTP_X_FORWARDED_FOR' => '10.0.0.1'
      expect(last_response.header['X-RateLimit-Remaining'].to_i).to eq(18)
    end
  end

  context 'when limit exceeded' do
    before(:each) { 20.times { get '/', {}, 'HTTP_X_FORWARDED_FOR' => '10.0.0.1' } }

    it 'prevents access' do
      expect(rack_app).not_to receive(:call)
      get '/', {}, 'HTTP_X_FORWARDED_FOR' => '10.0.0.1'
    end

    it 'returns 429 status' do
      get '/', {}, 'HTTP_X_FORWARDED_FOR' => '10.0.0.1'
      expect(last_response.status).to eq(429)
    end
  end

  context 'when time limit elapsed' do
    before(:each) { 10.times { get '/', {}, 'HTTP_X_FORWARDED_FOR' => '10.0.0.1' } }

    it 'resets limit' do
      expect(last_response.header['X-RateLimit-Remaining'].to_i).to eq(10)
      Timecop.freeze(Time.now + 4000) do
        get '/', {}, 'HTTP_X_FORWARDED_FOR' => '10.0.0.1'
        expect(last_response.header['X-RateLimit-Remaining'].to_i).to eq(19)
      end
    end

    it 'sets new time limit' do
      expect(last_response.header['X-RateLimit-Reset'].to_i).to be_within(2).of((Time.now + 3600).to_i)
      Timecop.freeze(Time.now + 4000) do
        get '/', {}, 'HTTP_X_FORWARDED_FOR' => '10.0.0.1'
        expect(last_response.header['X-RateLimit-Reset'].to_i).to be_within(2).of((Time.now + 3600).to_i)
      end
    end
  end

  context 'when different clients access app' do
    before(:each) { get '/', {}, 'HTTP_X_FORWARDED_FOR' => '10.0.0.1' }

    it 'distinguishes clients by IP' do
      expect(last_response.header['X-RateLimit-Remaining'].to_i).to eq(19)
      get '/', {}, 'HTTP_X_FORWARDED_FOR' => '10.0.0.2'
      expect(last_response.header['X-RateLimit-Remaining'].to_i).to eq(19)
    end
  end

  context 'when block is passed to middleware' do
    before(:each) { get '/', {}, 'HTTP_X_FORWARDED_FOR' => '10.0.0.1' }

    context 'when block returns nil' do
      let(:middleware) { Penguin::Middleware.new(rack_app, { limit: 20, reset_in: 3600 }) { nil } }

      it 'does not set limit' do
        expect(last_response.header['X-RateLimit-Limit']).to be_nil
      end
    end

    context 'when block returns custom key' do
      let(:middleware) { Penguin::Middleware.new(rack_app, { limit: 20, reset_in: 3600 }) { rand(1000000) } }

      it 'distinguishes client by custom key' do
        expect(last_response.header['X-RateLimit-Remaining'].to_i).to eq(19)
        get '/', {}, 'HTTP_X_FORWARDED_FOR' => '10.0.0.1'
        expect(last_response.header['X-RateLimit-Remaining'].to_i).to eq(19)
      end
    end
  end

  context 'when store is defined' do
    it 'invokes get and set methods' do
      expect(store).to receive(:get)
      2.times { expect(store).to receive(:set) }
      get '/', {}, 'HTTP_X_FORWARDED_FOR' => '10.0.0.1'
    end
  end
end
