# How To Run The Tests Locally

To run the tests for the SQL Server adapter in your local environment, refer to the documentation provided in the original gem repository: https://github.com/rails-sqlserver/activerecord-sqlserver-adapter


## Bundling

Now with that out of the way you can run "bundle install" to hook everything up. Our tests use bundler to setup the load paths correctly. The default mode is DBLIB using TinyTDS. It is important to use bundle exec so we can wire up the ActiveRecord test libs correctly.

```
$ bundle exec rake test
```


## Testing Options

The Gemfile contains groups for `:tinytds` and `:odbc`. By default it will install both gems which allows you to run the full test suite in either connection mode. If for some reason any one of these is problematic or of no concern, you could always opt out of bundling either gem with something like this.

```
$ bundle install --without odbc
```

You can run different connection modes using the following rake commands. Again, the DBLIB connection mode using TinyTDS is the default test task.

```
$ bundle exec rake test:dblib
$ bundle exec rake test:odbc
```

By default, Bundler will download the Rails git repo and use the git tag that matches the dependency version in our gemspec. If you want to test another version of Rails, you can either temporarily change the :tag for Rails in the Gemfile. Likewise, you can clone the Rails repo your self to another directory and use the `RAILS_SOURCE` environment variable.



## Troubleshooting

* Make sure your firewall is off or allows SQL Server traffic both ways, typically on port 1433.
* Ensure that you are running on a local admin login to create the Rails user.
* Possibly change the SQL Server TCP/IP properties in "SQL Server Configuration Manager -> SQL Server Network Configuration -> Protocols for MSSQLSERVER", and ensure that TCP/IP is enabled and the appropriate entries on the "IP Addresses" tab are enabled.
