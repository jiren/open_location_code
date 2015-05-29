module OpenLocationCode
  #
  # Decode open location code to latitude and longitude of the lower left and
  # upper right corners and the center of the bounding box for the area
  #
  class Decoder
    attr_accessor :code

    def initialize(code)
      @code = code.dup
    end

    #
    # Decode opne location code
    #
    # @return [CodeArea]
    #
    def process
      unless full?
        raise OLCError, "Passed Open Location Code is not a valid full code: #{code}"
      end

      # Strip out separator character (we've already established the code is
      # valid so the maximum is one), padding characters and convert to upper case.
      code.sub!(SEPARATOR, '')
      code.sub!(/#{PADDING_CHARACTER}+/, '')
      code.upcase!

      # Decode the lat/lng pair component.
      code_area = decode_pairs(code[0, PAIR_CODE_LENGTH])

      # If there is a grid refinement component, decode that.
      return code_area if code.length <= PAIR_CODE_LENGTH

      grid_area = decode_grid(code[PAIR_CODE_LENGTH, code.length - 1])

      CodeArea.new(
        code_area.latitude_lo + grid_area.latitude_lo,
        code_area.longitude_lo + grid_area.longitude_lo,
        code_area.latitude_lo + grid_area.latitude_hi,
        code_area.longitude_lo + grid_area.longitude_hi,
        code_area.code_length + grid_area.code_length
      )
    end

    #
    #  Decode an OLC code made up of lat/lng pairs.
    #
    #  This decodes an OLC code made up of alternating latitude and longitude
    #  characters, encoded using base 20.
    #
    # @param [String] code
    #   A valid OLC code, presumed to be full, but with the separator
    #   removed.
    # @return [CodeArea]
    #
    def decode_pairs(code)
      # Get the latitude and longitude values. These will need correcting from
      # positive ranges.

      latitude_pair = decode_pairs_sequence(code, 0)
      longitude_pair = decode_pairs_sequence(code, 1)

      # Correct the values and set them into the CodeArea object.
      return CodeArea.new(
        latitude_pair[0]  - LATITUDE_MAX,
        longitude_pair[0] - LONGITUDE_MAX,
        latitude_pair[1]  - LATITUDE_MAX,
        longitude_pair[1] - LONGITUDE_MAX,
        code.length)
    end

    #
    #  Decode either a latitude or longitude sequence.
    #
    #  This decodes the latitude or longitude sequence of a lat/lng pair encoding.
    #  Starting at the character at position offset, every second character is
    #  decoded and the value returned.
    #
    # @param [String] code
    #   A valid OLC code, presumed to be full, with the separator removed.
    # @param [Integer] offset
    #   The character to start from.
    # @return [CodeArea]
    #  A pair of the low and high values. The low value comes from decoding the
    #  characters. The high value is the low value plus the resolution of the
    #  last position. Both values are offset into positive ranges and will need
    #  to be corrected before use.
    #
    def decode_pairs_sequence(code, offset)
      i = 0
      value = 0

      while (i * 2 + offset) < code.length do
        value += CODE_ALPHABET.index(code[i * 2 + offset]) * PAIR_RESOLUTIONS[i]
        i += 1
      end

      [value, value + PAIR_RESOLUTIONS[i - 1]]
    end

    #
    #  Decode the grid refinement portion of an OLC code.
    #
    #  This decodes an OLC code using the grid refinement method.
    #
    #  @param [String] code
    #   A valid OLC code sequence that is only the grid refinement
    #   portion. This is the portion of a code starting at position 11.
    #  @return [CodeArea]
    #
    def decode_grid(code)
      latitude_lo = 0.0
      longitude_lo = 0.0
      lat_place_value = GRID_SIZE_DEGREES
      lng_place_value = GRID_SIZE_DEGREES
      i = 0

      while i < code.length do
        code_index = CODE_ALPHABET.index(code[i])
        row = (code_index.to_f / GRID_COLUMNS).floor
        col = code_index % GRID_COLUMNS

        lat_place_value /= GRID_ROWS
        lng_place_value /= GRID_COLUMNS

        latitude_lo += row * lat_place_value
        longitude_lo += col * lng_place_value
        i += 1
      end

      CodeArea.new(
        latitude_lo,
        longitude_lo,
        latitude_lo + lat_place_value,
        longitude_lo + lng_place_value,
        code.length
      )
    end

    #
    #  Determines if a code is a valid full Open Location Code.
    #
    #  Not all possible combinations of Open Location Code characters decode to
    #  valid latitude and longitude values. This checks that a code is valid
    #  and also that the latitude and longitude values are legal. If the prefix
    #  character is present, it must be the first character. If the separator
    #  character is present, it must be after four characters.
    #
    #  @return [Boolean]
    #
    def full?
      return false unless valid?

      # If it's short, it's not full.
      return false if short?

      # Work out what the first latitude character indicates for latitude.
      first_lat_value = CODE_ALPHABET.index(code[0].upcase) * ENCODING_BASE

      #The code would decode to a latitude of >= 90 degrees.
      return false if first_lat_value >= LATITUDE_MAX * 2

      if code.length > 1
        # Work out what the first longitude character indicates for longitude.
        first_lng_value = CODE_ALPHABET.index(code[1].upcase) * ENCODING_BASE

        # The code would decode to a longitude of >= 180 degrees.
        return false if first_lng_value >= LONGITUDE_MAX * 2
      end

      return true
    end

    #
    #  Determines if a code is valid.
    #
    #  To be valid, all characters must be from the Open Location Code character
    #  set with at most one separator. The separator can be in any even-numbered
    #  position up to the eighth digit.
    #
    #  @return [Boolean]
    #
    def valid?
      return false if code.nil? || code.length == 0

      # The separator is required.
      return false unless code.index(SEPARATOR)

      if code.index(SEPARATOR) != code.rindex(SEPARATOR)
        return false
      end

      # Is it in an illegal position?
      if code.index(SEPARATOR) > SEPARATOR_POSITION || code.index(SEPARATOR) % 2 == 1
        return false
      end

      # We can have an even number of padding characters before the separator,
      # but then it must be the final character.
      if code.index(PADDING_CHARACTER)
        # Not allowed to start with them!
        return false if code.index(PADDING_CHARACTER) == 0

        # There can only be one group and it must have even length.

        pad_match = code.scan(Regexp.new('(' + PADDING_CHARACTER + '+)')).collect{|m| m}

        if (pad_match.length > 1 || pad_match[0].length % 2 == 1 ||
            pad_match[0].length > SEPARATOR_POSITION - 2)
          return false
        end

        # If the code is long enough to end with a separator, make sure it does.
        return false if code[code.length - 1] != SEPARATOR
      end

      # If there are characters after the separator, make sure there isn't just
      # one of them (not legal).
      return false if (code.length - code.index(SEPARATOR) - 1) == 1

      # Strip the separator and any padding characters.
      code.sub!(Regexp.new('\\' + SEPARATOR + '+'), '')
      code.sub!(Regexp.new(PADDING_CHARACTER + '+'), '')

      # Check the code contains only valid characters.
      code.length.times.each do |i|
        character = code[i].upcase
        if (character != SEPARATOR && CODE_ALPHABET.index(character) == -1)
          return false
        end
      end
      return true
    end


    #
    #  Determines if a code is a valid short code.
    #
    #  A short Open Location Code is a sequence created by removing four or more
    #  digits from an Open Location Code. It must include a separator
    #  character.
    #
    #  @return [Boolean]
    #
    def short?
      # Check it's valid.
      return false unless valid?

      # If there are less characters than expected before the SEPARATOR.
      separator_index = code.index(SEPARATOR).to_i

      if separator_index >= 0 && separator_index < SEPARATOR_POSITION
        return true
      end

      return false
    end

  end
end
