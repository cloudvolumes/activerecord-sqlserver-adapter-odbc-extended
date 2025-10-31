# frozen_string_literal: true

module ActiveRecord
  module ConnectionAdapters
    module SQLServer
      module CoreExt
        module ODBC
          module Statement
            def finished?
              connected?
              false
            rescue ::ODBC::Error
              true
            end
          end

          module Database
            def run_block(*args)
              sth = run(*args)

              begin
                yield sth
              ensure
                sth.drop if sth && sth.connected?
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
