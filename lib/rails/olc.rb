module Olc
  extend ActiveSupport::Concern

  module ClassMethods

    # Default Olc options
    OLC_OPTIONS = {
      field: 'open_location_code',
      latitude: 'latitude',
      longitude: 'longitude',
      code_length: 10
    }

    #
    # Define before_save callback to generate olc code.
    #
    # @example
    #
    #   has_olc
    #   # or
    #   has_olc(field: 'olc', latitude: 'lat', longitude: 'lng', code_length: 10)
    #
    #
    # @params [Hash] options
    #   Default options
    #     {
    #       field: 'open_location_code',
    #       latitude: 'latitude',
    #       longitude: 'longitude',
    #       code_length: 10
    #     }
    #
    def has_olc(options = {})
      options = OLC_OPTIONS.merge(options)

      if defined?(Mongoid)
        field options[:field], type: String
      end

      before_save do |obj|
        lat_field = options[:latitude]
        lng_field = options[:longitude]

        changed_attrs = obj.changed_attributes

        if changed_attrs.key?(lat_field) || changed_attrs.key?(lng_field)
          if obj[lat_field] && obj[lng_field]
            obj[options[:field]] = obj.olc_encode(options[:code_length])
          else
            obj[options[:field]] = nil
          end
        end
      end

      class_eval <<-RUBY, __FILE__, __LINE__ + 1
        def olc_encode(code_length = nil)
          OpenLocationCode.encode(#{options[:latitude]}, #{options[:longitude]}, code_length)
        end

        def olc_decode
          OpenLocationCode.decode(#{options[:field]})
        end
      RUBY
    end
  end

end
