describe WebMock::Twirp::RequestSignatureSnippet do
  let(:client) { EchoClient.new("http://localhost/twirp") }
  let(:twirp_request) { EchoRequest.new(msg: "woof") }

  def rpc
    client.echo(twirp_request)
  end

  describe ".new" do
    subject { WebMock::RequestSignatureSnippet.new(request) }

    context "with a Twirp request" do
      let(:request) do
        capture_request { rpc }
      end

      it { expect(request).to be_a(WebMock::RequestSignature) }

      it "hijacks .new to create a subclass instance" do
        is_expected.to be_a(described_class)
      end
    end

    context "with a standard request" do
      let(:request) do
        capture_request { Faraday.get('http://example.com') }
      end

      it { is_expected.to be_a(WebMock::RequestSignatureSnippet) }
      it { is_expected.not_to be_a(described_class) }
    end
  end

  describe "#stubbing_instructions" do
# You can stub this request with the following snippet:

# stub_twirp_request(:echo).with(
#   msg: "woof",
# )

    it "suggests how to stub using webmock-twirp" do
      expect { rpc }.to raise_error(/stub_twirp_request/)
    end

    it "suggests the Twirp client and method" do
      expect { rpc }.to raise_error(
        %r{stub_twirp_request\(:echo\)}
      )
    end

    it "includes param matching" do
      expect { rpc }.to raise_error(/msg: "woof"/)
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
