describe :make_twirp_request do
  let(:client) { EchoClient.new("http://localhost/twirp") }
  let(:request) { EchoRequest.new(msg: "woof") }

  def rpc
    @rpc ||= client.echo(request)
  rescue WebMock::NetConnectNotAllowedError
    nil
  end

  it "exists" do
    respond_to?(:make_twirp_request)
  end

  it { expect { rpc }.to make_twirp_request }

  it "catches false negatives" do
    expect {
      expect { rpc }.not_to make_twirp_request
    }.to fail
  end

  describe ".with" do
    it "matches attribures" do
      expect { rpc }.to make_twirp_request.with(msg: /woof/)
    end

    it "does not match the wrong attribute" do
      expect {
        expect { rpc }.to make_twirp_request.with(msg: /foo/)
      }.to fail
    end

    it "works with a negation matcher" do
      expect { rpc }.not_to make_twirp_request.with(msg: /foo/)
    end

    it "returns nil by default, which causes a client error" do
      expect {
        expect(rpc).to be_a(Twirp::ClientResp)
        expect(rpc.error.code).to be :internal
        expect(rpc.error.msg).to match(/but found nil/)
      }.to make_twirp_request
    end
  end

  describe ".and_return" do
    it do
      expect {
        expect(rpc).to be_a(Twirp::ClientResp)
        expect(rpc.data).to be_a(EchoResponse)
        expect(rpc.data.msg).to eq "hi"
      }.to make_twirp_request.and_return(msg: "hi")
    end

    it "chains" do
      expect {
        expect(rpc.data.msg).to eq "hi"
      }.to make_twirp_request.with(msg: /w/).and_return(msg: "hi")
    end
  end

  it "only works with a block" do
    expect {
      expect(Object).to make_twirp_request
    }.to raise_error(ArgumentError)
  end

  it "has an alias" do
    expect { rpc }.to make_a_twirp_request
  end
end
