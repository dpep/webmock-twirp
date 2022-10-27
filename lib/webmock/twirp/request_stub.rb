module WebMock
  module Twirp
    class RequestStub < WebMock::RequestStub
      using Refinements

      def initialize(*filters)
        rpc_name = filters.snag { |x| x.is_a?(Symbol) }

        client = filters.snag { |x| x.is_a?(::Twirp::Client) }

        klass = client&.class
        klass ||= filters.snag do |x|
          x.is_a?(Class) && (x < ::Twirp::Client || x < ::Twirp::Service)
        end

        unless filters.empty?
          raise ArgumentError, "unexpected arguments: #{filters}"
        end

        uri = ""

        if client
          conn = client.instance_variable_get(:@conn)
          uri += conn.url_prefix.to_s.chomp("/") if conn
        end

        if klass
          @rpcs = klass.rpcs
          uri += "/#{klass.service_full_name}"
        else
          uri += "/[^/]+"
        end

        if rpc_name
          if klass
            # kindly convert ruby method to rpc method name
            rpc_info = klass.rpcs.values.find do |x|
              x[:rpc_method] == rpc_name || x[:ruby_method] == rpc_name
            end

            raise ArgumentError, "invalid rpc method: #{rpc_name}" unless rpc_info

            uri += "/#{rpc_info[:rpc_method]}"
          else
            uri += "/#{rpc_name}"
          end
        else
          uri += "/[^/]+"
        end

        super(:post, /#{uri}$/)

        # filter on Twirp header
        @request_pattern.with(
          headers: { "Content-Type" => ::Twirp::Encoding::PROTO },
        )
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

        decoder = ->(request_signature) do
          request = request_signature.twirp_request

          matched = !!request
          matched &&= request.include?(attrs) if attrs.any?
          matched &&= block.call(request) if block

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
            generate_http_response(request, response)
          end
        end

        decoder = ->(request) do
          generate_http_response(
            request,
            block.call(request.twirp_request),
          )
        end if block_given?

        super(*response_hashes, &decoder)
      end
      alias_method :and_return, :to_return # update existing alias

      def to_return_json(*)
        raise NotImplementedError
      end

      private

      def generate_http_response(request, obj)
        msg_class = request.twirp_rpc&.fetch(:output_class)

        if msg_class.nil?
          raise "could not determine Twirp::Client for request: #{request}"
        end

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
            raise ArgumentError, "invalid http error status: #{obj}"
          end
        else
          raise ArgumentError, "can not generate twirp reponse from: #{obj}"
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
