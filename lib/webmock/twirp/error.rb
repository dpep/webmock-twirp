module WebMock
  module Twirp
    module NetConnectNotAllowedError
      def initialize(request_signature)
        @request_signature = request_signature
      end

      def message
        snippet = WebMock::RequestSignatureSnippet.new(@request_signature)

        text = [
          "Real Twirp connections are disabled. Unregistered request:",
          @request_signature,
          snippet.stubbing_instructions,
          snippet.request_stubs,
          "="*60
        ].compact.join("\n\n")
      end
    end
  end
end

# hijack creation of Twirp errors
module WebMock
  class NetConnectNotAllowedError
    def self.new(request_signature)
      allocate.tap do |instance|
        if request_signature.is_a?(WebMock::Twirp::RequestSignature)
          instance.extend(WebMock::Twirp::NetConnectNotAllowedError)
        end

        instance.send(:initialize, request_signature)
      end
    end
  end
end

