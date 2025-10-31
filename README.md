# ActiveRecord SQL Server Adapter ODBC Extended

* [![CI](https://github.com/cloudvolumes/activerecord-sqlserver-adapter-odbc-extended/actions/workflows/ci.yml/badge.svg)](https://github.com/cloudvolumes/activerecord-sqlserver-adapter-odbc-extended/actions/workflows/ci.yml) - CI


## About The Adapter

This gem extends the ActiveRecord SQL Server adapter by adding enhanced functionality and customization, including ODBC support. It is compatible with both FreeTDS and ODBC connections.

We follow a versioning policy aligned with the ActiveRecord SQLServer Adapter. This means that version 8.x of this extended adapter corresponds to and supports the latest 8.x version of the activerecord-sqlserver-adapter gem.

We support the versions of the adapter that are in the Rails [Bug Fixes](https://rubyonrails.org/maintenance)
maintenance group.


| Adapter Version | Rails Version | Support        | Branch                                                                                             |
|-----------------|---------------|----------------|----------------------------------------------------------------------------------------------------|
| `8.0.x`         | `8.0.x`       | Active         | [8-0-stable](https://github.com/cloudvolumes/activerecord-sqlserver-adapter-odbc-extended/tree/8-0-stable) |



## Using the TinyTDS Driver

If you are using the TinyTDS driver, please refer to the original gem’s README for setup and version details: https://github.com/rails-sqlserver/activerecord-sqlserver-adapter/tree/8-0-stable


### Database configuration


Example:

```yaml
development:
  adapter: sqlserver
  mode: 'dblib'
  host: 'localhost'
  port: 1433
  database: my_app_development
  username: 'frank_castle'
  password: 'secret'
```


## Using the ODBC Driver

### Features

- Extends ActiveRecord::ConnectionAdapters::SQLServerAdapter
- Adds custom connection logic and methods
- Supports ODBC and DBLIB modes


### Installation


1. Add to Gemfile
```ruby
gem 'activerecord-sqlserver-adapter-odbc-extended', '~> 8.0.9'
```

2. Bundle install and Database configuration
```
bundle install
```

Example:

```yaml
development:
  adapter: sqlserver
  mode: 'odbc'
  host: 'localhost'
  port: 1433
  database: my_app_development
  username: 'frank_castle'
  password: 'secret'
```


## Contributing

Please contribute to the project by submitting bug fixes and features. To make sure your fix/feature has
a high chance of being added, please include tests in your pull request. To run the tests you will need to
setup your development environment.


## Setting Up Your Development Environment

To run the test suite you can use any of the following methods below. See [RUNNING_UNIT_TESTS](RUNNING_UNIT_TESTS.md) for
more detailed information on running unit tests.


### Local Development

See the [RUNNING_UNIT_TESTS](RUNNING_UNIT_TESTS.md) file for the details of how to run the unit tests locally.


## Credits & Contributions



## License

ActiveRecord SQL Server Adapter with ODBC Support is released under the [MIT License](https://opensource.org/licenses/MIT).
