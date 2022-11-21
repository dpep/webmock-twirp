module WebMock
  module Twirp
    module Matchers
      class MakeTwirpRequest
        def initialize(*matchers)
          @stub = WebMock::Twirp::RequestStub.new(*matchers)
        end

        def method_missing(name, *args, **kwargs, &block)
          return super unless respond_to_missing?(name)
          @stub.send(name, *args, **kwargs, &block)

          self
        end

        def respond_to_missing?(method_name, include_private = false)
          @stub.respond_to?(method_name)
        end

        def matches?(block)
          unless block.is_a?(Proc)
            raise ArgumentError, "expected block, found: #{block}"
          end

          WebMock::StubRegistry.instance.register_request_stub(@stub)
          block.call
          WebMock::StubRegistry.instance.remove_request_stub(@stub)

          RequestRegistry.instance.times_executed(@stub) > 0
        end

        def failure_message
          "expected a Twirp request but received none"
        end

        def failure_message_when_negated
          "did not expect a Twirp request, but received one"
        end

        def supports_block_expectations?
          true
        end
      end
    end
  end
end
