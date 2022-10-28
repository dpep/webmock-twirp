using WebMock::Twirp::Refinements

module WebMock
  module Twirp
    module RequestBodyDiff

      private

      def request_signature_diffable?
        !!request_signature.twirp_request
      end

      def request_stub_diffable?
        !!request_stub.with_attrs && !request_stub.with_attrs.is_a?(Proc)
      end

      def request_signature_body_hash
        request_signature.twirp_request.normalized_hash
      end

      def request_stub_body_hash
        request_stub.with_attrs
      end
    end
  end
end

# hijack creation of Twirp snippets
module WebMock
  class RequestBodyDiff
    def self.new(request_signature, request_stub)
      super.tap do |instance|
        if request_signature.proto_headers? && request_stub.is_a?(WebMock::Twirp::RequestStub)
          instance.extend(WebMock::Twirp::RequestBodyDiff)
        end
      end
    end
  end
end
