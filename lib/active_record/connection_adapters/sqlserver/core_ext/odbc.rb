# frozen_string_literal: true

module ActiveRecord
  module ConnectionAdapters
    module SQLServer
      module CoreExt
        module ODBC
          # Adds helper methods for handling ODBC statement objects.
          # Provides a safe implementation of +finished?+ to check
          # connection state and handle ODBC errors gracefully.
          module Statement
            def finished?
              connected?
              false
            rescue ::ODBC::Error
              true
            end
          end

          # Adds helper methods for ODBC database operations.
          # Wraps execution blocks to ensure statement handles are
          # properly released after use, preventing connection leaks.
          module Database
            def run_block(*args)
              sth = run(*args)

              begin
                yield sth
              ensure
                sth.drop if sth&.connected?
              end
            end
          end
        end
      end
    end
  end
end

ODBC::Statement.include ActiveRecord::ConnectionAdapters::SQLServer::CoreExt::ODBC::Statement
ODBC::Database.include ActiveRecord::ConnectionAdapters::SQLServer::CoreExt::ODBC::Database
