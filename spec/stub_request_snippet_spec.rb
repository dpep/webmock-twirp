describe WebMock::Twirp::StubRequestSnippet do
  using WebMock::Twirp::Refinements

  let(:client) { EchoClient.new("http://localhost/twirp") }
  let(:twirp_request) { EchoRequest.new(msg: "woof") }

  def rpc
    client.echo(twirp_request)
  end

  describe ".new" do
    subject { WebMock::StubRequestSnippet.new(a_stub) }

    context "with a Twirp stub" do
      let(:a_stub) do
        stub_twirp_request(:echo)
      end

      it "hijacks .new to create a subclass instance" do
        is_expected.to be_a(described_class)
      end
    end

    context "with a standard stub" do
      let(:a_stub) do
        stub_request(:get, //)
      end

      it { is_expected.to be_a(WebMock::StubRequestSnippet) }
      it { is_expected.not_to be_a(described_class) }
    end
  end

  describe "#to_s" do
    subject { WebMock::StubRequestSnippet.new(a_stub).to_s }

    context "with a generic stub" do
      let(:a_stub) { stub_twirp_request }

      it { is_expected.to eq "stub_twirp_request" }
    end

    context "with a ruby method name" do
      let(:a_stub) { stub_twirp_request(:echo) }

      it { is_expected.to eq "stub_twirp_request(:echo)" }
    end

    context "with a RPC name" do
      let(:a_stub) { stub_twirp_request(:Echo) }

      it { is_expected.to eq "stub_twirp_request(:Echo)" }
    end

    context "with a client" do
      let(:a_stub) { stub_twirp_request(EchoClient) }

      it { is_expected.to eq "stub_twirp_request(EchoClient)" }
    end

    context "with a client instance" do
      let(:a_stub) { stub_twirp_request(client) }

      it { is_expected.to eq "stub_twirp_request(EchoClient)" }
    end

    context "with a client and rpc" do
      let(:a_stub) { stub_twirp_request(EchoClient, :Echo) }

      it { is_expected.to eq "stub_twirp_request(EchoClient, :Echo)" }
    end

    context "with a client and ruby method" do
      let(:a_stub) { stub_twirp_request(EchoClient, :echo) }

      it { is_expected.to eq "stub_twirp_request(EchoClient, :echo)" }
    end

    describe ".with" do
      context "with a hash" do
        let(:a_stub) { stub_twirp_request.with(msg: "woof") }

        it do
          is_expected.to eq(
            "stub_twirp_request.with(\n  msg: \"woof\",\n)"
          )
        end
      end

      context "with a proto" do
        let(:a_stub) { stub_twirp_request.with(twirp_request) }

        it do
          is_expected.to eq(
            "stub_twirp_request.with(\n  #{twirp_request}\n)"
          )
        end
      end

      context "with a block" do
        let(:a_stub) { stub_twirp_request.with {} }

        it do
          is_expected.to eq(
            "stub_twirp_request.with(\n  { ... }\n)"
          )
        end
      end
    end
  end
end
