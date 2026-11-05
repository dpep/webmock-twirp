module WebMock
  module Twirp
    module Refinements
      # Message#to_h, but keeping default-valued fields, which google-protobuf 4 drops
      def self.to_h_with_defaults(value)
        case value
        when Google::Protobuf::MessageExts
          value.class.descriptor.to_h do |field|
            [ field.name.to_sym, to_h_with_defaults(field.get(value)) ]
          end
        when Google::Protobuf::RepeatedField
          value.map { |x| to_h_with_defaults(x) }
        when Google::Protobuf::Map
          # Map#to_h ignores a block
          res = {}
          value.each { |k, v| res[k] = to_h_with_defaults(v) }
          res
        else
          value
        end
      end

      refine Array do
        def snag(&block)
          find(&block)&.tap { |x| delete(x) }
        end
      end

      refine Google::Protobuf::MessageExts do
        def normalized_hash
          res = {}

          self.class.descriptor.each do |field|
            key = field.name.to_sym
            value = field.get(self)

            if value.is_a?(Google::Protobuf::MessageExts)
              # recursively serialize sub-message
              value = value.normalized_hash
            end

            res[key] = value unless field.default == value
          end

          res
        end

        def include?(*args)
          expected_attrs = Hash === args.last ? args.pop : {}

          # ensure all enumerated keys are present
          return false unless args.all? { |attr| respond_to?(attr) }

          # ensure all enumerated attributes are present
          return false unless expected_attrs.keys.all? { |attr| respond_to?(attr) }

          # check expected attribute matches
          expected_attrs.all? do |expected_attr, expected_value|
            actual_value = send(expected_attr)

            matches = expected_value === actual_value

            if actual_value.is_a?(Google::Protobuf::MessageExts)
              if expected_value.is_a?(Hash)
                matches ||= actual_value.match?(**expected_value)
              else
                matches ||= expected_value === Refinements.to_h_with_defaults(actual_value)
              end
            end

            matches
          end
        end

        def match?(**attrs)
          # ensure all enumerated keys are present
          return false unless attrs.keys.all? { |attr| respond_to?(attr) }

          # ensure each field matches
          self.class.descriptor.all? do |field|
            actual_value = field.get(self)
            expected_value = attrs[field.name.to_sym]

            if actual_value.is_a?(Google::Protobuf::MessageExts) && expected_value.is_a?(Hash)
              actual_value.match?(**expected_value)
            else
              attrs.fetch(field.name.to_sym, field.default) === actual_value
            end
          end
        end
      end

      refine ::WebMock::RequestSignature do
        def proto_headers?
          !!(headers&.fetch("Content-Type", nil)&.start_with?(::Twirp::Encoding::PROTO))
        end
      end
    end
  end
end
