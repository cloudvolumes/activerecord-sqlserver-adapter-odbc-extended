# frozen_string_literal: true

module ActiveRecord
  module ConnectionAdapters
    module SQLServer
      module Type
        class Binary
          def cast_value(value)
            if value.class.to_s == 'String' and !value.frozen?
              value.force_encoding(Encoding::BINARY) =~ /[^[:xdigit:]]/ ? value : [value].pack('H*')
            else
              value
            end
          end
        end
      end
    end
  end
end
