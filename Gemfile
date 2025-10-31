# frozen_string_literal: true

source "https://rubygems.org"

gemspec

gem "minitest", "~> 5.16"
gem "rake", "~> 13.0"

group :odbc do
  gem "ruby-odbc", git: "https://github.com/cloudvolumes/ruby-odbc.git", tag: "0.103.cv"
end

group :rubocop do
  gem "rubocop", "~> 1.21", require: false
end
