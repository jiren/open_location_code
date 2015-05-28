# OpenLocationCode

Welcome to your new gem! In this directory, you'll find the files you need to be able to package up your Ruby library into a gem. Put your Ruby code in the file `lib/open_location_code`. To experiment with that code, run `bin/console` for an interactive prompt.

Ref:  https://github.com/google/open-location-code


## Installation

Add this line to your application's Gemfile:

```ruby
gem 'open_location_code', github: 'jiren/open_location_code'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install open_location_code

## Usage

```ruby
  code = OpenLocationCode.encode(47.365590, 8.524997) # 8FVC9G8F+6X
  code = OpenLocationCode.encode(47.365590, 8.524997, 12) #8FVC9G8F+6XQH
 
  code_area = OpenLocationCode.decode(code)
  # #<OpenLocationCode::CodeArea:0x007fe7eb050110 @latitude_lo=47.36557499999997, @longitude_lo=8.524968750000008, @latitude_hi=47.36557499999997, @longitude_hi=8.52500000000001, @code_length=12, @latitude_center=47.36557499999997, @longitude_center=8.52498437500001>
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release` to create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

1. Fork it ( https://github.com/[my-github-username]/open_location_code/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
