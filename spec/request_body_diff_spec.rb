describe WebMock::Twirp::RequestBodyDiff do
  subject do
    WebMock::RequestBodyDiff.new(request, twirp_stub).body_diff.first
  end

  let(:client) { EchoClient.new("http://localhost/twirp") }
  let(:request) { capture_request { client.echo(req_attrs) } }

  context "with attribute hash" do
    context "when request is missing an attribute" do
      let(:req_attrs) { {} }
      let(:twirp_stub) { stub_twirp_request.with(msg: "Hi") }

      it { is_expected.to eq [ "+", "msg", "Hi" ] }
    end

    context "when request has wrong attribute" do
      let(:req_attrs) { { msg: "bye" } }
      let(:twirp_stub) { stub_twirp_request.with(msg: "Hi") }

      it { is_expected.to eq [ "~", "msg", "bye", "Hi" ] }
    end

    context "when request is a proto and missing an attribute" do
      let(:req_attrs) { EchoRequest.new }
      let(:twirp_stub) { stub_twirp_request.with(msg: "Hi") }

      it { is_expected.to eq [ "+", "msg", "Hi" ] }
    end
  end

  context "with proto" do
    context "when request is missing an attribute" do
      let(:req_attrs) { EchoRequest.new }
      let(:twirp_stub) { stub_twirp_request.with(msg: "Hi") }

      it { is_expected.to eq [ "+", "msg", "Hi" ] }
    end

    context "when request has wrong attribute" do
      let(:req_attrs) { EchoRequest.new(msg: "bye") }
      let(:twirp_stub) { stub_twirp_request.with(msg: "Hi") }

      it { is_expected.to eq [ "~", "msg", "bye", "Hi" ] }
    end
  end
end
