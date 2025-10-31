# frozen_string_literal: true

module ActiveRecord
  module ConnectionAdapters
    module SQLServer

      # Removes default SQL Server implementations of +exec_update+ and +exec_delete+
      # so they can be replaced by ODBC-specific versions.
      # Otherwise, when calling +super+ from the OdbcDatabaseStatements module,
      # Ruby’s ancestor chain would still include this module and invoke
      # the original TinyTDS-based methods.
      module DatabaseStatements
        remove_method :exec_update
        remove_method :exec_delete
      end

      # Module: OdbcDatabaseStatements
      #
      # Provides ODBC-specific SQL execution methods for the SQL Server adapter.
      # This module overrides default DatabaseStatements methods to handle
      # ODBC driver behavior, such as statement handle cleanup and row count
      # retrieval through @@ROWCOUNT.
      #
      # When included, this module replaces the default TinyTDS-based methods
      # removed from +DatabaseStatements+, ensuring correct behavior for ODBC
      # connections and allowing +super+ calls without invoking the removed methods.
      #
      module OdbcDatabaseStatements

        def affected_rows(raw_result)
          return if raw_result.blank?

          column_name = lowercase_schema_reflection ? "affectedrows" : "AffectedRows"
          raw_result.first[column_name]
        end

        def internal_exec_sql_query(sql, conn)
          handle = internal_raw_execute(sql, conn)
          handle_to_names_and_values(handle, ar_result: true)
        ensure
          finish_statement_handle(handle)
        end

        def exec_delete(sql, name = nil, binds = [])
          super || super("SELECT @@ROWCOUNT As AffectedRows", "", [])
        end

        def exec_update(sql, name = nil, binds = [])
          super || super("SELECT @@ROWCOUNT As AffectedRows", "", [])
        end

        # === SQLServer Specific ======================================== #

        def execute_procedure(proc_name, *variables)
          vars = if variables.any? && variables.first.is_a?(Hash)
                   variables.first.map { |k, v| "@#{k} = #{quote(v)}" }
                 else
                   variables.map { |v| quote(v) }
                 end.join(", ")
          sql = "EXEC #{proc_name} #{vars}".strip

          log(sql, "Execute Procedure") do |notification_payload|
            with_raw_connection do |conn|
              result = execute_odbc_procedure(sql, conn)
              notification_payload[:row_count] = result&.count
              result
            end
          end
        end

        protected

        def sql_for_insert(sql, pk, binds, returning)
          if pk.nil?
            table_name = query_requires_identity_insert?(sql)
            pk = primary_key(table_name)
          end

          sql = if pk && use_output_inserted? && !database_prefix_remote_server?
                  table_name ||= get_table_name(sql)
                  exclude_output_inserted = exclude_output_inserted_table_name?(table_name, sql)

                  if exclude_output_inserted
                    pk_and_types = Array(pk).map do |subkey|
                      {
                        quoted: SQLServer::Utils.extract_identifiers(subkey).quoted,
                        id_sql_type: exclude_output_inserted_id_sql_type(subkey, exclude_output_inserted)
                      }
                    end

                    <<-SQL.strip_heredoc
                      SET NOCOUNT ON
                      DECLARE @ssaIdInsertTable table (#{pk_and_types.map { |pk_and_type| "#{pk_and_type[:quoted]} #{pk_and_type[:id_sql_type]}"}.join(", ") });
                      #{sql.dup.insert sql.index(/ (DEFAULT )?VALUES/), " OUTPUT #{ pk_and_types.map { |pk_and_type| "INSERTED.#{pk_and_type[:quoted]}" }.join(", ")} INTO @ssaIdInsertTable"}
                      SELECT #{pk_and_types.map {|pk_and_type| "CAST(#{pk_and_type[:quoted]} AS #{pk_and_type[:id_sql_type]}) #{pk_and_type[:quoted]}"}.join(", ")} FROM @ssaIdInsertTable;
                      SET NOCOUNT OFF
                    SQL
                  else
                    returning_columns = returning || Array(pk)

                    if returning_columns.any?
                      returning_columns_statements = returning_columns.map { |c| " INSERTED.#{SQLServer::Utils.extract_identifiers(c).quoted}" }
                      sql.dup.insert sql.index(/ (DEFAULT )?VALUES/i), " OUTPUT" + returning_columns_statements.join(",")
                    else
                      sql
                    end
                  end
                else
                  table = get_table_name(sql)
                  id_column = identity_columns(table.to_s.strip).first

                  if id_column.present?
                    sql.sub(/\s*VALUES\s*\(/, " OUTPUT INSERTED.#{id_column.name} VALUES (")
                  else
                    sql.sub(/\s*VALUES\s*\(/, " OUTPUT CAST(SCOPE_IDENTITY() AS bigint) AS Ident VALUES (")
                  end
                end

          [sql, binds]
        end

        # === SQLServer Specific ======================================== #

        def set_identity_insert(table_name, conn, enable)
          internal_raw_execute("SET IDENTITY_INSERT #{table_name} #{enable ? 'ON' : 'OFF'}", conn, perform_do: true)
        rescue Exception
          raise ActiveRecordError, "IDENTITY_INSERT could not be turned #{enable ? 'ON' : 'OFF'} for table #{table_name}"
        end

        def sp_executesql_sql_type(attr)
          if attr.respond_to?(:type)
            type = attr.type.is_a?(ActiveRecord::Normalization::NormalizedValueType) ? attr.type.cast_type : attr.type
            type = type.subtype if type.serialized?

            return type.sqlserver_type if type.respond_to?(:sqlserver_type)

            if type.is_a?(ActiveRecord::Encryption::EncryptedAttributeType) && type.instance_variable_get(:@cast_type).respond_to?(:sqlserver_type)
              return type.instance_variable_get(:@cast_type).sqlserver_type
            end
          end

          value = active_model_attribute?(attr) ? attr.value_for_database : attr

          if value.is_a?(Numeric)
            if value.is_a?(Integer)
              value > 2_147_483_647 ? "bigint" : "int"
            else
              # For Float, BigDecimal, Rational etc.
              value.is_a?(BigDecimal) ? "decimal(18,6)" : "float"
            end
          else
            "nvarchar(max)"
          end
        end

        # === SQLServer Specific (Selecting) ============================ #

        def _raw_select(sql, conn)
          handle = internal_raw_execute(sql, conn)
          handle_to_names_and_values(handle, fetch: :rows)
        ensure
          finish_statement_handle(handle)
        end

        def handle_to_names_and_values(handle, options = {})
          @raw_connection.use_utc = ActiveRecord.default_timezone || :utc

          if options[:ar_result]
            columns = lowercase_schema_reflection ? handle.columns(true).map { |c| c.name.downcase } : handle.columns(true).map { |c| c.name }
            rows = handle.fetch_all || []
            ActiveRecord::Result.new(columns, rows)
          else
            case options[:fetch]
            when :all
              handle.each_hash || []
            when :rows
              handle.fetch_all || []
            end
          end
        end

        def finish_statement_handle(handle)
          return unless handle

          handle.drop if handle.respond_to?(:drop) && !handle.finished?
          handle
        end

        # Executing SQL for ODBC mode
        def internal_raw_execute(sql, raw_connection, perform_do: false)
          return raw_connection.do(sql) if perform_do

          block_given? ? raw_connection.run_block(sql) { |handle| yield(handle) } : raw_connection.run(sql)
        end

        private

        def execute_odbc_procedure(sql, conn)
          results = []

          internal_raw_execute(sql, conn) do |handle|
            get_rows = lambda do
              rows = handle_to_names_and_values handle, fetch: :all
              results << rows.map!(&:with_indifferent_access)
            end

            get_rows.call
            get_rows.call while handle_more_results?(handle)
          end

          results.many? ? results : results.first
        end

        def handle_more_results?(handle)
          handle.more_results
        end
      end
    end
  end
end
