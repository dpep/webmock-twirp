module WebMock
  module Twirp
    module Refinements
      refine Array do
        def snag(&block)
          find(&block)&.tap { |x| delete(x) }
        end
      end

      refine Google::Protobuf::MessageExts do
        def normalized_hash(symbolize_keys: true)
          res = {}

          self.class.descriptor.each do |field|
            key = symbolize_keys ? field.name.to_sym : field.name
            value = field.get(self)

            if value.is_a?(Google::Protobuf::MessageExts)
              # recursively serialize sub-message
              value = value.normalized_hash(symbolize_keys: symbolize_keys)
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
                matches ||= expected_value === actual_value.to_h
                # matches ||= expected_value === actual_value.normalized_hash
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
