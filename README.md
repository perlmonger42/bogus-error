# Bogus::Error

This gem allows you to raise spurious errors as specified by a JSON control
file.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'bogus-error'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install https://github.com/perlmonger42/ruby-bogus-error.git

## Usage

Call the error-generator like this:

```ruby
Bogus::Error.generate(logger, __FILE__)
```

from a Ruby source file named like
`/any/path/followed/by/the/directory/app/whatever/something_handler.rb`
or
`/any/path/followed/by/a/directory/named/app/something_controller.rb`

The `logger` should respond to a `debug` method with a single argument.

The generate method will open a file named
`/any/path/followed/by/the/directory/app/config/handler_bogus_errors.rb`
or
`/any/path/followed/by/a/directory/named/app/config/controller_bogus_errors.rb`
as indicated by the `_handler.rb` or `_controller.rb` suffix of your Ruby source
file name.

To cause the generation of an ArgumentError (for example), the json file should
contain:
```json
{"something":"ArgumentError"}
```
(because the Ruby source file was named `something_*.rb`).

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/perlmonger42/ruby-bogus-error.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
