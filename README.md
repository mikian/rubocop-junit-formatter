# Rubocop::Junit::Formatter

Provides JUnit formatting for Rubocop. Usable with Continuous integration services and IDEs.

## Usage

In order to have the formatter available inside CLI utility, you need to require it first.

Example for CI, that provides `$REPORTS_DIR` environment variable for collecting JUnit reports

```bash
bundle exec rubocop \\
  -r $(bundle show rubocop-junit-formatter)/lib/rubocop/formatter/junit_formatter.rb \\
  --format RuboCop::Formatter::JUnitFormatter --out $REPORTS_DIR/rubocop.xml
```

Important options are `-r` (require class) and `--format`. Option `--out` should go after appropriate `--format`.
And you can have multiple formats if you like.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'rubocop-junit-formatter'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install rubocop-junit-formatter

## Contributing

1. Fork it ( https://github.com/[my-github-username]/rubocop-junit-formatter/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
