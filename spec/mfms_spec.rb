require 'spec_helper'
require 'mfms'

RSpec.describe Mfms::SMS do
  before(:all) do
    Mfms::SMS.settings = [
      {'first' => {
        login: 'johndoe',
        password: 'password',
        server: 'sms_server.com',
        port: 9673,
        ssl_port: 9674,
        cert: './spec/support/alice.crt',
        translit: true,
        connector: 'connector3',
        priority: 'normal',
        default: true
      }}
    ]
  end

  describe '.status' do
    let(:message_id) { '1234567' }
    let(:status_url) { "https://sms_server.com:9674/revoup/connector3/status?login=johndoe&password=password&providerId[0]=#{message_id}" }

    subject { described_class.status(message_id) }

    context 'success' do
      before { stub_request(:get, status_url).to_return(body: "ok;#{message_id};delivered;2017-02-15 10:35:41;") }

      it { is_expected.to eq(["ok", "delivered"]) }
    end

    context 'failure' do
      before { stub_request(:get, status_url).to_return(body: 'error-provider-id-unknown;53156321111;;;') }

      it { is_expected.to eq(["error-provider-id-unknown", nil]) }
    end

    context 'failure: bad HTTP code' do
      before { stub_request(:get, status_url).to_return(status: 500) }

      it 'fails with proper exception' do
        expect { subject }.to raise_error(described_class::RequestFailure)
      end
    end

    context 'failure: HTTP timeout' do
      before { stub_request(:get, status_url).to_timeout }

      it 'fails with proper exception' do
        expect { subject }.to raise_error(described_class::RequestFailure)
      end
    end
  end
end
