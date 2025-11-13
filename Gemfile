# frozen_string_literal: true

source "https://rubygems.org"

gemspec

is_windows = %i[mingw x64_mingw mswin x64_mingw_ucrt].include?(RUBY_PLATFORM.gsub("-", "_").to_sym)

gem "minitest", "~> 5.16"
gem "rake", "~> 13.0"

group :development do
  gem "minitest-spec-rails"
  gem "mocha"
  gem "pry-byebug", platform: %i[mri mingw x64_mingw]
end

group :odbc do
  install_if -> { is_windows } do
    gem "ruby-odbc", git: "https://github.com/cloudvolumes/ruby-odbc.git", tag: "0.103.cv"
  end
end

group :rubocop do
  gem "rubocop", "~> 1.21", require: false
end
