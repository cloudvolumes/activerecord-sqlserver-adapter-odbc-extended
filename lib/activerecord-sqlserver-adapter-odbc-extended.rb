# frozen_string_literal: true

require "active_record"
require "odbc_utf8"

# Ensure we only patch after ActiveRecord and the base SQL Server adapter are loaded
ActiveSupport.on_load(:active_record) do
  require "activerecord-sqlserver-adapter"
  require "active_record/connection_adapters/sqlserver_adapter"
  require "active_record/connection_adapters/sqlserver/type/binary_ext"
  require "active_record/connection_adapters/extended_sqlserver_adapter"
end
