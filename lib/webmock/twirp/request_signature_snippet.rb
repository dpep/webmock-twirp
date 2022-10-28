using WebMock::Twirp::Refinements

module WebMock
  module Twirp
    module RequestSignatureSnippet
      def stubbing_instructions
        return unless WebMock.show_stubbing_instructions?

        client = @request_signature.twirp_client
        rpc = @request_signature.twirp_rpc

        return super unless client

        string = "You can stub this request with the following snippet:\n\n"
        string << "stub_twirp_request(#{rpc[:ruby_method].inspect})"

        if request = @request_signature.twirp_request
          params = request.normalized_hash.map do |k, v|
            "  #{k}: #{v.inspect},"
          end.join("\n")

          string << ".with(\n#{params}\n)" unless params.empty?
        end

        string << ".to_return(...)"
      end
    end
  end
end

# hijack creation of Twirp snippets
module WebMock
  class RequestSignatureSnippet
    def self.new(request_signature)
      super.tap do |instance|
        instance.extend(WebMock::Twirp::RequestSignatureSnippet) if request_signature.proto_headers?
      end
    end
  end
end
