# using WebMock::Twirp::Refinements

describe WebMock::Twirp::NetConnectNotAllowedError do
  # subject { WebMock::NetConnectNotAllowedError.new(request) }

  let(:client) { EchoClient.new("http://localhost/twirp") }

  describe ".new" do
    subject { WebMock::NetConnectNotAllowedError.new(request) }

    context "with a Twirp request" do
      let(:request) { capture_request { client.echo({}) } }

      it "hijacks .new to create a subclass instance" do
        is_expected.to be_a(described_class)
      end
    end

    context "with a standard request" do
      let(:request) do
        capture_request { Faraday.get('http://example.com') }
      end

      it { is_expected.to be_a(WebMock::NetConnectNotAllowedError) }
      it { is_expected.not_to be_a(described_class) }
    end
  end

  describe "#message" do
    subject do
      WebMock::NetConnectNotAllowedError.new(request).message
    end

    before { stub_twirp_request(:Foo) }

    let(:request) { capture_request { client.echo({}) } }

    it { is_expected.to include "Real Twirp connections are disabled" }
  end
end
