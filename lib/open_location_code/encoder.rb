module OpenLocationCode
  #
  # Encode latitude longitude to code
  #
  class Encoder
    attr_accessor :latitude, :longitude, :code_length, :original

    def initialize(latitude, longitude, code_length)
      @code_length = code_length

      # Ensure that latitude and longitude are valid.
      @latitude = clip_latitude(latitude)
      @longitude = normalize_longitude(longitude)

      @original = { latitude: latitude, longitude: longitude }
    end

    #
    # Clip a latitude into the range -90 to 90.
    #
    # @param [Float] latitude
    # @return [Float]
    #
    def clip_latitude(latitude)
      [ 90, [-90, latitude].max ].min
    end

    #
    # Normalize a longitude into the range -180 to 180, not including 180.
    #
    # @param [Float] longitude
    # @return [Float]
    #
    def normalize_longitude(longitude)
      while (longitude < -180) do
        longitude += 360
      end

      while (longitude >= 180) do
        longitude -= 360
      end

      longitude
    end

    #
    #  Compute the latitude precision value for a given code length. Lengths <=
    #  10 have the same precision for latitude and longitude, but lengths > 10
    #  have different precisions due to the grid method having fewer columns than
    #  rows.
    #
    def compute_latitude_precision
      if code_length <= 10
        return 20**(code_length/-2.0 + 2).floor
      end

      (20**-3).to_f/GRID_ROWS**(code_length - 10)
    end

    #
    # Encode a location into a sequence of OLC lat/lng pairs.
    #
    # This uses pairs of characters (longitude and latitude in that order) to
    # represent each step in a 20x20 grid. Each code, therefore, has 1/400th
    # the area of the previous code.
    #
    # @param [Integer] code_length
    #   The number of significant digits in the output code, not
    #   including any separator characters.
    #
    def encode_pairs(code_length)
      code = ''

      # Adjust latitude and longitude so they fall into positive ranges.
      adjusted_latitude = latitude + LATITUDE_MAX
      adjusted_longitude = longitude + LONGITUDE_MAX

      # Count digits - can't use string length because it may include a separator
      # character.
      digit_count = 0

      while (digit_count < code_length) do
        # Provides the value of digits in this place in decimal degrees.
        place_value = PAIR_RESOLUTIONS[(digit_count / 2.0).floor]

        # Do the latitude - gets the digit for this place and subtracts that for
        # the next digit.
        digit_value = (adjusted_latitude / place_value.to_f).floor
        adjusted_latitude -= (digit_value * place_value)
        code += CODE_ALPHABET[digit_value]
        digit_count += 1

        # And do the longitude - gets the digit for this place and subtracts that
        # for the next digit.
        digit_value = (adjusted_longitude / place_value.to_f).floor
        adjusted_longitude -= (digit_value * place_value)
        code += CODE_ALPHABET[digit_value]
        digit_count += 1

        # Should we add a separator here?
        if digit_count == SEPARATOR_POSITION && digit_count < code_length
          code += SEPARATOR
        end
      end

      if code.length < SEPARATOR_POSITION
        code += PADDING_CHARACTER*(SEPARATOR_POSITION - code.length + 1)
      end

      if code.length == SEPARATOR_POSITION
        code += SEPARATOR
      end

      return code
    end

    #  Encode a location using the grid refinement method into an OLC string.
    #
    #  The grid refinement method divides the area into a grid of 4x5, and uses a
    #  single character to refine the area. This allows default accuracy OLC codes
    #  to be refined with just a single character.
    #
    #  @param [Integer] code_length
    #
    def encode_grid(code_length)
      code = ''
      lat_place_value = GRID_SIZE_DEGREES
      lng_place_value = GRID_SIZE_DEGREES

      # Adjust latitude and longitude so they fall into positive ranges and
      # get the offset for the required places.
      adjusted_latitude = (latitude + LATITUDE_MAX) % lat_place_value
      adjusted_longitude = (longitude + LONGITUDE_MAX) % lng_place_value

      code_length.times do |i|
        # Work out the row and column.
        row = (adjusted_latitude / (lat_place_value.to_f / GRID_ROWS)).floor
        col = (adjusted_longitude / (lng_place_value.to_f / GRID_COLUMNS)).floor

        lat_place_value /= GRID_ROWS
        lng_place_value /= GRID_COLUMNS

        adjusted_latitude -= (row * lat_place_value)
        adjusted_longitude -= (col * lng_place_value)

        code += CODE_ALPHABET[row * GRID_COLUMNS + col]
      end

      return code
    end

    #
    # Encode latitude and longitude
    #
    # @return [String]
    #
    def process
      if code_length < 2 || (code_length < SEPARATOR_POSITION && code_length % 2 == 1)
        raise OLCError, 'Invalid Open Location Code length'
      end

      # Latitude 90 needs to be adjusted to be just less, so the returned code
      # can also be decoded.
      if latitude == 90
        self.latitude -= compute_latitude_precision
      end

      code = encode_pairs([code_length, PAIR_CODE_LENGTH].min)

      # If the requested length indicates we want grid refined codes.
      if code_length > PAIR_CODE_LENGTH
        code += encode_grid(code_length - PAIR_CODE_LENGTH)
      end

      code
    end

  end
end
