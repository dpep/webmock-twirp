describe "stub_twirp_request" do
  let(:client) { EchoClient.new("http://localhost/twirp") }
  let(:other_client) { EchoClient.new("http://otherhost/twirp") }
  let(:request) { EchoRequest.new(msg: "woof") }
  let(:response) { EchoResponse.new(msg: "woof") }
  let(:error) { Twirp::Error.new(:not_found, "Not There") }

  def rpc
    @rpc ||= client.echo(request)
  end

  def expect_stub_failure
    expect {
      block_given? ? yield : rpc
    }.to raise_error(WebMock::NetConnectNotAllowedError)
  end

  after do
    if @stub
      rpc
      expect(@stub).to have_been_requested
    end
  end

  it "stubs twirp requests" do
    @stub = stub_twirp_request
  end

  it "explodes without a stub" do
    expect_stub_failure
  end

  describe "destination filters" do
    it "stubs requests from a specific client" do
      @stub = stub_twirp_request(client)
    end

    it "does not stub requests from different clients" do
      stub_twirp_request(client)

      expect_stub_failure do
        other_client.echo(request)
      end
    end

    it "stubs requests from a client class" do
      stub = stub_twirp_request(client.class)

      client.echo(request)
      other_client.echo(request)

      expect(stub).to have_been_requested.twice
    end

    it "stubs requests to a twirp service" do
      stub = stub_twirp_request(EchoService)

      client.echo(request)
      other_client.echo(request)

      expect(stub).to have_been_requested.twice
    end

    context "when a uri is specified" do
      let(:uri) { "http://localhost/twirp" }

      it { @stub = stub_twirp_request(uri) }
      it { @stub = stub_twirp_request(uri, EchoClient) }
      it { @stub = stub_twirp_request(uri, :echo) }

      it "does not permit client also" do
        expect {
          stub_twirp_request(uri, client)
        }.to raise_error(ArgumentError)
      end
    end

    it "catches bogus input" do
      expect {
        stub_twirp_request(Object)
      }.to raise_error(ArgumentError, /unexpected arguments/)
    end

    context "when client url has trailing /" do
      let(:client) { EchoClient.new("http://localhost/twirp/") }

      it "normalizes and stubs properly" do
        @stub = stub_twirp_request(client)
      end
    end

    context "when a specific rpc method is specified" do
      it "stubs a specific twirp request" do
        stub = stub_twirp_request(:Echo)

        client.echo(request)
        other_client.echo(request)

        expect(stub).to have_been_requested.twice
      end

      it "can handle ruby method names" do
        @stub = stub_twirp_request(:echo)
      end

      it "supports both client and rpc method name" do
        @stub = stub_twirp_request(client, :Echo)

        expect_stub_failure do
          other_client.echo(request)
        end
      end

      it "supports both client and ruby method name" do
        @stub = stub_twirp_request(client, :echo)

        expect_stub_failure do
          other_client.echo(request)
        end
      end

      it "only stubs the specified rpc method" do
        stub_twirp_request(:Double)
        stub_twirp_request(:double)
        expect_stub_failure
      end

      it "handles unknown rpcs gracefully" do
        stub_twirp_request(:foo)
        expect_stub_failure
      end

      it "catches erroneous rpc names when client is provided" do
        expect {
          stub_twirp_request(EchoClient, :foo)
        }.to raise_error(ArgumentError)
      end

      it "works with client and rpc are out of order" do
        @stub = stub_twirp_request(:echo, EchoClient)
      end
    end
  end

  describe ".with" do
    it "matches attributes" do
      @stub = stub_twirp_request.with(msg: "woof")
    end

    it "matches an attribute regex" do
      @stub = stub_twirp_request.with(msg: /^w/)
    end

    it "matches proto messages" do
      @stub = stub_twirp_request.with(request)
    end

    it "does not stub mismatches" do
      stub_twirp_request.with(msg: "rav")
      stub_twirp_request.with(msg: /rav/)
      stub_twirp_request.with(EchoRequest.new)
      stub_twirp_request.with { false }

      expect_stub_failure
    end

    it "supports Ruby 2 style attributes-as-hash instead of kwargs" do
      @stub = stub_twirp_request.with({ msg: "woof" })
    end

    it "does not permit a request and attrs" do
      expect {
        stub_twirp_request.with(request, **request.to_h)
      }.to raise_error(ArgumentError, /specify request or attrs/)
    end

    it "type checks the request param" do
      expect {
        stub_twirp_request.with(Object)
      }.to raise_error(TypeError, /to be Protobuf::MessageExts/)
    end

    context "with block mode" do
      it "passes in a twirp message instance" do
        @stub = stub_twirp_request.with do |request|
          expect(request).to be_a(EchoRequest)
        end
      end

      it "can be used to match request attributes" do
        @stub = stub_twirp_request.with do |request|
          request.msg == "woof"
        end
      end

      it "does not stub if the block returns false" do
        stub_twirp_request.with do |request|
          request.msg == "xyz"
        end

        expect_stub_failure
      end
    end

    context "with rspec matchers" do
      it { @stub = stub_twirp_request.with(msg: eq("woof")) }
      it { @stub = stub_twirp_request.with(msg: start_with("w")) }
      it { @stub = stub_twirp_request.with(msg: include("oo")) }

      it "works within blocks" do
        @stub = stub_twirp_request.with do |request|
          respond_to(:msg) & having_attributes(msg: "woof") === request
        end
      end
    end

    context "when no corresponding Twirp::Client is found" do
      it "does not match" do
        stub_twirp_request.with(msg: "woof")

        expect {
          Faraday.post(
            "http://localhost/twirp/Foo/foo",
            request.to_proto,
            { "Content-Type" => ::Twirp::Encoding::PROTO },
          )
        }.to raise_error(WebMock::NetConnectNotAllowedError)
      end
    end
  end

  describe ".to_return" do
    it "defaults to a default response" do
      @stub = stub_twirp_request.to_return

      expect(rpc).to be_a(Twirp::ClientResp)
      expect(rpc.data).to be_a(EchoResponse)
    end

    it "supports attributes" do
      @stub = stub_twirp_request.to_return(msg: "rav")
      expect(rpc.data.msg).to eq "rav"
    end

    it "supports proto messages" do
      @stub = stub_twirp_request.to_return(response)
      expect(rpc.data.msg).to eq response.msg
    end

    it "supports proto message types" do
      @stub = stub_twirp_request.to_return(EchoResponse)
      expect(rpc.data).to be_a(EchoResponse)
      expect(rpc.data.msg).to be_empty
    end

    it "supports Twirp errors" do
      @stub = stub_twirp_request.to_return(error)
      expect(rpc.error).to be_a(Twirp::Error)
      expect(rpc.error.code).to be error.code
      expect(rpc.error.msg).to eq error.msg
    end

    it "supports Twirp error codes" do
      @stub = stub_twirp_request.to_return(:not_found)
      expect(rpc.error).to be_a(Twirp::Error)
      expect(rpc.error.code).to be :not_found
      expect(rpc.error.msg).to eq "not_found"
    end

    it "supports http error codes" do
      @stub = stub_twirp_request.to_return(404)
      expect(rpc.error).to be_a(Twirp::Error)
      expect(rpc.error.code).to be :not_found
      expect(rpc.error.msg).to eq "not_found"
    end

    it "works with the and_return alias" do
      @stub = stub_twirp_request.and_return(404)
      expect(rpc.error).to be_a(Twirp::Error)
    end

    context "with block mode" do
      it "passes in the Twirp request" do
        @stub = stub_twirp_request.to_return do |request|
          expect(request).to be_a(EchoRequest)
          nil
        end
      end

      it "defaults to the default response" do
        @stub = stub_twirp_request.to_return {}

        expect(rpc).to be_a(Twirp::ClientResp)
        expect(rpc.data).to be_a(EchoResponse)
      end

      it "supports attribute hashes" do
        @stub = stub_twirp_request.to_return do
          { msg: "boo" }
        end

        expect(rpc.data.msg).to eq "boo"
      end

      it "supports proto messages" do
        @stub = stub_twirp_request.to_return { response }
        expect(rpc.data.msg).to eq response.msg
      end

      context "with a Twirp::ClientResp" do
        it "repackages proto messages" do
          stub_twirp_request.to_return(
            Twirp::ClientResp.new(data: response)
          )

          expect(rpc.data).to eq(response)
          expect(rpc.error).to be nil
        end

        it "repackages errors" do
          stub_twirp_request.to_return(
            Twirp::ClientResp.new(error: error)
          )

          expect(rpc.data).to be nil
          expect(rpc.error).to be_a(Twirp::Error)
          expect(rpc.error.to_h).to eq(error.to_h)
        end
      end

      it "supports Twirp errors" do
        @stub = stub_twirp_request.to_return { error }
        expect(rpc.error).to be_a(Twirp::Error)
        expect(rpc.error.to_h).to eq(error.to_h)
      end

      it "supports Twirp error codes" do
        @stub = stub_twirp_request.to_return(:not_found)
        expect(rpc.error).to be_a(Twirp::Error)
        expect(rpc.error.code).to be :not_found
      end

      it "supports http error codes" do
        @stub = stub_twirp_request.to_return { 404 }
        expect(rpc.error).to be_a(Twirp::Error)
        expect(rpc.error.code).to be :not_found
      end

      it "type checks the response" do
        stub_twirp_request.to_return { request }

        expect {
          rpc
        }.to raise_error(TypeError, /Expected type EchoResponse/)
      end
    end

    context "when used erroneously" do
      def check_for(*matchers)
        expect { rpc }.to raise_error(*matchers)
      end

      it "catches response type mismatches" do
        stub_twirp_request.to_return(request)
        check_for(TypeError, /Expected type EchoResponse/)
      end

      it "catches bogus error codes" do
        stub_twirp_request.to_return(:boom)
        check_for(ArgumentError, /invalid error code/)
      end

      it "catches bogus http status codes" do
        stub_twirp_request.to_return(200)
        check_for(ArgumentError, /invalid http error status/)
      end

      it "catches bogus responses" do
        stub_twirp_request.to_return(Object)
        check_for(TypeError, /Object/)
      end

      it "does not permit a response and block" do
        expect {
          stub_twirp_request.to_return(response) { 500 }
        }.to raise_error(ArgumentError, /specify responses or block/)
      end
    end

    it "works after a with block" do
      @stub = stub_twirp_request.with do |request|
        request.msg == "woof"
      end.and_return(msg: "woof woof")

      expect(rpc.data.msg).to eq "woof woof"
    end

    it "raises when no corresponding Twirp::Client is found" do
      stub_twirp_request.to_return(msg: "woof")

      expect {
        Faraday.post(
          "http://localhost/twirp/Foo/foo",
          request.to_proto,
          { "Content-Type" => ::Twirp::Encoding::PROTO },
        )
      }.to raise_error(/could not determine Twirp::Client/)
    end
  end

  describe ".to_return_json" do
    it "is unsupported" do
      expect {
        stub_twirp_request.to_return_json(response.to_h)
      }.to raise_error(NotImplementedError)
    end
  end
end
