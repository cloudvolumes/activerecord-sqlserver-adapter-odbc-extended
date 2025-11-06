# frozen_string_literal: true

module ActiveRecord
  module ConnectionAdapters
    # Extends the ActiveRecord SQL Server adapter with custom behavior
    # and compatibility fixes for ODBC and SQL Server–specific features.
    # Provides overrides for query execution, type casting, and schema handling.
    class SQLServerAdapter
      class << self
        def new_client(config)
          case config[:mode].to_sym
          when :dblib
            dblib_connect(config)
          when :odbc
            odbc_connect(config)
          else
            raise ArgumentError, "Unknown connection mode in #{config.inspect}."
          end
        end

        def dblib_connect(config)
          TinyTds::Client.new(config)
        rescue TinyTds::Error => e
          raise ActiveRecord::NoDatabaseError if e.message.match(/database .* does not exist/i)

          raise e.message
        end

        def odbc_connect(config)
          raise ArgumentError, "Missing :dsn configuration." unless config.key?(:dsn)

          if config[:dsn].include?(";")
            driver = ODBC::Driver.new.tap do |d|
              d.name = config[:dsn_name] || "Driver1"
              d.attrs = config[:dsn].split("\n").map do |atr|
                atr.split("=")
              end.select { |kv| kv.size == 2 }.each_with_object({}) do |e, a|
                k, v = e
                a[k] = v
              end
            end

            ODBC::Database.new.drvconnect(driver)
          else
            ODBC.connect config[:dsn], config[:username], config[:password]
          end.tap do |c|
            c.use_time = true
            c.use_utc = ActiveRecord.default_timezone || :utc
          rescue StandardError
            warn "Ruby ODBC v0.99992 or higher is required."
          end
        rescue ODBC::Error => e
          raise ActiveRecord::NoDatabaseError if e.message.match(/database .* does not exist/i)

          raise e.message
        end
      end

      def initialize(...)
        super

        @config[:tds_version] ||= "7.3" if @config[:mode].to_sym == :dblib
        @config[:appname] = self.class.rails_application_name unless @config[:appname]
        @config[:login_timeout] = @config[:login_timeout].present? ? @config[:login_timeout].to_i : nil
        @config[:timeout] = @config[:timeout].present? ? @config[:timeout].to_i / 1000 : nil
        @config[:encoding] = @config[:encoding].present? ? @config[:encoding] : nil

        @connection_parameters ||= @config

        apply_mode_specific_behavior
      end
      # === Abstract Adapter (Connection Management) ================== #

      def active?
        return false unless @raw_connection

        @connection_parameters[:mode].to_sym == :dblib ? @raw_connection.active? : odbc_connection_active?
      rescue *connection_errors
        false
      end

      def odbc_connection_active?
        @raw_connection.do("SELECT 1")
        true
      rescue *connection_errors
        false
      end

      def reconnect
        case @connection_parameters[:mode].to_sym
        when :dblib
          begin
            @raw_connection&.close
          rescue StandardError
            nil
          end
        when :odbc
          begin
            @raw_connection&.disconnect
          rescue StandardError
            nil
          end
        end

        @raw_connection = nil
        @spid = nil
        @collation = nil

        connect
      end

      def disconnect!
        super

        case @connection_parameters[:mode].to_sym
        when :dblib
          begin
            @raw_connection&.close
          rescue StandardError
            nil
          end
        when :odbc
          begin
            @raw_connection&.disconnect
          rescue StandardError
            nil
          end
        end

        @raw_connection = nil
        @spid = nil
        @collation = nil
      end

      # === SQLServer Specific (Connection Management) ================ #

      protected

      def connection_errors
        @connection_errors ||= [].tap do |errors|
          errors << TinyTds::Error if defined?(TinyTds::Error)
          errors << ODBC::Error if defined?(ODBC::Error)
        end
      end

      private

      def configure_connection
        send("configure_#{@config[:mode]}_connection")

        @spid = _raw_select("SELECT @@SPID", @raw_connection).first.first

        initialize_dateformatter
        use_database
      end

      def configure_dblib_connection
        if @config[:azure]
          @raw_connection.execute("SET ANSI_NULLS ON").do
          @raw_connection.execute("SET ANSI_NULL_DFLT_ON ON").do
          @raw_connection.execute("SET ANSI_PADDING ON").do
          @raw_connection.execute("SET ANSI_WARNINGS ON").do
        else
          @raw_connection.execute("SET ANSI_DEFAULTS ON").do
        end

        @raw_connection.execute("SET QUOTED_IDENTIFIER ON").do
        @raw_connection.execute("SET CURSOR_CLOSE_ON_COMMIT OFF").do
        @raw_connection.execute("SET IMPLICIT_TRANSACTIONS OFF").do
        @raw_connection.execute("SET TEXTSIZE 2147483647").do
        @raw_connection.execute("SET CONCAT_NULL_YIELDS_NULL ON").do
      end

      def configure_odbc_connection
        if @config[:azure]
          @raw_connection.do("SET ANSI_NULLS ON")
          @raw_connection.do("SET ANSI_NULL_DFLT_ON ON")
          @raw_connection.do("SET ANSI_PADDING ON")
          @raw_connection.do("SET ANSI_WARNINGS ON")
        else
          @raw_connection.do("SET ANSI_DEFAULTS ON")
        end

        @raw_connection.do("SET QUOTED_IDENTIFIER ON")
        @raw_connection.do("SET CURSOR_CLOSE_ON_COMMIT OFF")
        @raw_connection.do("SET IMPLICIT_TRANSACTIONS OFF")
        @raw_connection.do("SET TEXTSIZE 2147483647")
        @raw_connection.do("SET CONCAT_NULL_YIELDS_NULL ON")

        @raw_connection.do("SET LOCK_TIMEOUT 45000")
      end

      def apply_mode_specific_behavior
        return if @config[:mode].to_sym != :odbc

        require "odbc"
        require "active_record/connection_adapters/sqlserver/core_ext/odbc"
        require "active_record/connection_adapters/sqlserver/odbc_database_statements"

        ActiveRecord::ConnectionAdapters::SQLServerAdapter.prepend SQLServer::OdbcDatabaseStatements
      end
    end
  end
end
