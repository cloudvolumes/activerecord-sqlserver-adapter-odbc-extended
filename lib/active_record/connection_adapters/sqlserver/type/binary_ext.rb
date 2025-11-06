# frozen_string_literal: true

module ActiveRecord
  module ConnectionAdapters
    module SQLServer
      module Type
        # Extends SQL Server binary type handling in ActiveRecord.
        # Adds a custom +cast_value+ implementation to properly encode or
        # convert binary (varbinary) values from hex strings.
        class Binary
          # Custom override to handle binary casting for SQL Server.
          # Ensures non-frozen strings are forced to binary encoding
          # or packed from hex when needed.
          def cast_value(value)
            if value.instance_of?(::String) && !value.frozen?
              value.force_encoding(Encoding::BINARY) =~ /[^[:xdigit:]]/ ? value : [value].pack("H*")
            else
              value
            end
          end
        end
      end
    end
  end
end
