describe WebMock::Twirp::RequestSignature do
  let(:client) { EchoClient.new("http://localhost/twirp") }
  let(:twirp_request) { EchoRequest.new(msg: "woof") }
  let(:request) do
    capture_request { client.echo(twirp_request) }
  end

  describe ".new" do
    context "with a Twirp request" do
      subject { capture_request { client.echo(twirp_request) } }

      it { is_expected.to be_a(WebMock::RequestSignature) }

      it "hijacks .new to create a subclass instance" do
        is_expected.to be_a(described_class)
      end
    end

    context "with a standard request" do
      subject do
        capture_request { Faraday.get('http://example.com') }
      end

      it { is_expected.to be_a(WebMock::RequestSignature) }
      it { is_expected.not_to be_a(described_class) }
    end
  end

  describe "#twirp_client" do
    subject { request.twirp_client }

    it { is_expected.to be < ::Twirp::Client }
    it { is_expected.to be EchoClient }
  end

  describe "#twirp_rpc" do
    subject { request.twirp_rpc }

    it { is_expected.to be_a(Hash) }
    it { is_expected.to eq(EchoClient.rpcs["Echo"]) }
  end

  describe "#twirp_request" do
    subject { request.twirp_request }

    it { is_expected.to be_a(EchoRequest) }
    it { is_expected.to eq(twirp_request) }
  end

  describe "#to_s" do
    subject { request.to_s }
    # Twirp EchoClient(http://localhost/twirp/Echo/Echo).echo(msg: "woof")

    it "is Twirpy" do
      is_expected.to match(
        %r{EchoClient\(.*\).echo\(msg: "woof"\)}
      )
    end

    it "gets used to display stub failures" do
      expect { client.echo(twirp_request) }.to raise_error(
        %r{EchoClient\(.*\).echo\(msg: "woof"\)}
      )
    end

    it "does not change non-twirp stub failures" do
      expect {
        Faraday.get('http://example.com')
      }.to raise_error(
        %r{stub_request\(:get, "http://example.com/"\)}
      )
    end
  end
end
