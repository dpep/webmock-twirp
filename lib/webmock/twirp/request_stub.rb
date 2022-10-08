module WebMock
  module Twirp
    class RequestStub < WebMock::RequestStub
      def initialize(client_or_service, rpc_name = nil)
        klass = client_or_service.is_a?(Class) ? client_or_service : client_or_service.class

        unless klass < ::Twirp::Client || klass < ::Twirp::Service
          raise TypeError, "expected Twirp Client or Service, found: #{client_or_service}"
        end

        @rpcs = klass.rpcs
        uri = "/#{klass.service_full_name}"

        if rpc_name
          rpc_info = rpcs.values.find do |x|
            x[:rpc_method] == rpc_name.to_sym || x[:ruby_method] == rpc_name.to_sym
          end

          raise ArgumentError, "invalid rpc method: #{rpc_name}" unless rpc_info

          uri += "/#{rpc_info[:rpc_method]}"
        else
          uri += "/[^/]+"
        end

        super(:post, /#{uri}$/)
      end

      def with(request = nil, **attrs, &block)
        unless request.nil? || attrs.empty?
          raise ArgumentError, "specify request or attrs, but not both"
        end

        request_matcher = if request
          unless request.is_a?(Google::Protobuf::MessageExts)
            raise TypeError, "Expected request to be Protobuf::MessageExts, found: #{request}"
          end

          { body: request.to_proto }
        end

        decoder = ->(request) do
          input_class = rpc_from_request(request)[:input_class]

          matched = true
          decoded_request = input_class.decode(request.body)

          if attrs.any?
            attr_matcher = Matchers::HashIncludingMatcher.new(**attrs)
            attr_hash = WebMock::Util::HashKeysStringifier.stringify_keys!(decoded_request.to_h, deep: true)

            matched &= attr_matcher === attr_hash
          end

          if block
            matched &= block.call(decoded_request)
          end

          matched
        end if attrs.any? || block_given?

        super(request_matcher || {}, &decoder)
      end

      def to_return(*responses, &block)
        unless responses.empty? || block.nil?
          raise ArgumentError, "specify responses or block, but not both"
        end

        # if no args, provide default response
        responses << nil if responses.empty? && block.nil?

        response_hashes = responses.map do |response|
          ->(request) do
            # determine msg type and package response
            output_class = rpc_from_request(request)[:output_class]
            generate_http_response(output_class, response)
          end
        end

        decoder = ->(request) do
          # determine msg type and call provided block
          rpc = rpc_from_request(request)
          res = block.call(rpc[:input_class].decode(request.body))
          generate_http_response(rpc[:output_class], res)
        end if block_given?

        super(*response_hashes, &decoder)
      end

      def to_return_json(*)
        raise NotImplementedError
      end

      private

      attr_reader :rpcs

      def rpc_from_request(request_signature)
        rpcs[request_signature.uri.path.split("/").last]
      end

      def generate_http_response(msg_class, obj)
        res = case obj
        when nil
          msg_class.new
        when Hash
          msg_class.new(**obj)
        when Google::Protobuf::MessageExts
          unless obj.is_a?(msg_class)
            raise TypeError, "Expected type #{msg_class}, found #{obj}"
          end

          obj
        when ::Twirp::Error
          obj
        when Symbol
          if ::Twirp::Error.valid_code?(obj)
            ::Twirp::Error.new(obj, obj)
          else
            raise ArgumentError, "invalid error code: #{obj}"
          end
        when Integer
          if code = ::Twirp::ERROR_CODES_TO_HTTP_STATUS.key(obj)
            ::Twirp::Error.new(code, code)
          else
            raise ArgumentError, "invalid error code: #{obj}"
          end
        else
          raise NotImplementedError
        end

        if res.is_a?(Google::Protobuf::MessageExts)
          {
            status: 200,
            headers: { "Content-Type" => ::Twirp::Encoding::PROTO },
            body: res.to_proto,
          }
        else # Twirp::Error
          {
            status: ::Twirp::ERROR_CODES_TO_HTTP_STATUS[res.code],
            headers: { "Content-Type" => ::Twirp::Encoding::JSON },
            body: ::Twirp::Encoding.encode_json(res.to_h),
          }
        end
      end
    end
  end
end
