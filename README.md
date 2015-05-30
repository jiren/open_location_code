# OpenLocationCode

Open Location Codes are a way of encoding location into a form that is
easier to use than latitude and longitude.

Ref:  https://github.com/google/open-location-code


## Installation

Add this line to your application's Gemfile:

```ruby
gem 'open_location_code'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install open_location_code

## Usage

```ruby
  code = OpenLocationCode.encode(47.365590, 8.524997) # 8FVC9G8F+6X
  code = OpenLocationCode.encode(47.365590, 8.524997, 12) #8FVC9G8F+6XQH
 
  code_area = OpenLocationCode.decode('8FVC9G8F+6XQH')
  # #<OpenLocationCode::CodeArea:0x007fe7eb050110 @latitude_lo=47.36557499999997, @longitude_lo=8.524968750000008, @latitude_hi=47.36557499999997, @longitude_hi=8.52500000000001, @code_length=12, @latitude_center=47.36557499999997, @longitude_center=8.52498437500001>
```

## Rails

  Include `Olc` module and call `has_olc` method

  `has_olc` has default options `{ field: 'open_location_code', latitude: 'latitude', longitude: 'longitude', code_length: 10 }`


- ActiveRecord

  Generate migration to add latitude, longitude and open_location_code fields.

```
  rails g migration add_olc_fields_to_events latitude:float longitude:float open_location_code:string
```

  In Model:

```
  class Event < < ActiveRecord::Base
    include Olc

    has_olc

    # If fields not same as default options
    has_olc(field: 'olc', latitude: 'lat', longitude: 'lng', code_length: 10)
  end
```

- Mongoid

  `has_olc` will define field based on passed options[:field] value.

```
  class Event
     include Mongoid::Document
     include Olc
      
     field :latitude,   type: Float
     field :longitude,  type: Float

     has_olc
  end
```

  

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release` to create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

1. Fork it ( https://github.com/jiren/open_location_code )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
