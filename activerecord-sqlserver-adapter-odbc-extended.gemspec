# frozen_string_literal: true

version = File.read(File.expand_path("VERSION", __dir__)).strip

Gem::Specification.new do |spec|
  spec.name    = "activerecord-sqlserver-adapter-odbc-extended"
  spec.version = version
  spec.authors = ["Jyothish"]
  spec.email   = ["jyothu.kr@gmail.com"]

  spec.platform    = Gem::Platform::RUBY
  spec.homepage    = "http://github.com/cloudvolumes/activerecord-sqlserver-adapter-odbc-extended"
  spec.summary     = "ActiveRecord SQL Server Adapter with ODBC support."
  spec.description = "ActiveRecord SQL Server Adapter. SQL Server 2012 and upward."
  spec.license     = "MIT"

  spec.required_ruby_version       = ">= 3.2.0"
  spec.metadata["homepage_uri"]    = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/cloudvolumes/activerecord-sqlserver-adapter-odbc-extended/tree/v#{version}"
  spec.metadata["changelog_uri"]   = "https://github.com/cloudvolumes/activerecord-sqlserver-adapter-odbc-extended/blob/v#{version}/CHANGELOG.md"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency "activerecord-sqlserver-adapter", "~> 8.0.0"

  # Define Windows check (reuse your logic)
  is_windows = %i[mingw x64_mingw mswin x64_mingw_ucrt].include?(
    RUBY_PLATFORM.gsub("-", "_").to_sym
  )

  spec.add_dependency "ruby-odbc-supported" if is_windows
end
