module WebMock
  module Twirp
    module StubRequestSnippet
      def to_s(with_response = true)
        string = "stub_twirp_request"

        filters = [
          @request_stub.twirp_client,
          @request_stub.rpc_name&.inspect,
        ].compact.join(", ")
        string << "(#{filters})" unless filters.empty?

        if attrs = @request_stub.with_attrs
          string << ".with(\n"

          if attrs.is_a?(Hash)
            string << attrs.map do |k, v|
              "  #{k}: #{v.inspect},"
            end.join("\n")
          elsif attrs.is_a?(Proc)
            string << "  { ... }"
          else
            string << "  #{attrs}"
          end

          string << "\n)"
        end

        string
      end
    end
  end
end

# hijack creation of Twirp snippets
module WebMock
  class StubRequestSnippet
    def self.new(request_stub)
      super.tap do |instance|
        if request_stub.is_a?(WebMock::Twirp::RequestStub)
          instance.extend(WebMock::Twirp::StubRequestSnippet)
        end
      end
    end
  end
end
