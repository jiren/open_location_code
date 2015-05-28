require 'open_location_code/version'
require 'open_location_code/code_area'

#  Examples:
#
#    Encode a location, default accuracy:
#    code = OpenLocationCode.encode(47.365590, 8.524997)
#
#    Encode a location using one stage of additional refinement:
#    code = OpenLocationCode.encode(47.365590, 8.524997, 11)
#
#    Decode a full code:
#    coord = OpenLocationCode.decode(code)
#
#    Attempt to trim the first characters from a code:
#    shortCode = OpenLocationCode.shorten('8FVC9G8F+6X', 47.5, 8.5)
#
#    Recover the full code from a short code:
#    code = OpenLocationCode.recoverNearest('9G8F+6X', 47.4, 8.6)
#    code = OpenLocationCode.recoverNearest('8F+6X', 47.4, 8.6)
module OpenLocationCode
  module_function

  # A separator used to break the code into two parts to aid memorability
  SEPARATOR = '+'

  # The number of characters to place before the separator.
  SEPARATOR_POSITION = 8

  # The character used to pad codes.
  PADDING_CHARACTER = '0'

  # The character set used to encode the values.
  CODE_ALPHABET = '23456789CFGHJMPQRVWX'

  # The base to use to convert numbers to/from.
  ENCODING_BASE = CODE_ALPHABET.length

  # The maximum value for latitude in degrees.
  LATITUDE_MAX = 90

  # The maximum value for longitude in degrees.
  LONGITUDE_MAX = 180

  # Maxiumum code length using lat/lng pair encoding. The area of such a
  # code is approximately 13x13 meters (at the equator), and should be suitable
  # for identifying buildings. This excludes prefix and separator characters.
  PAIR_CODE_LENGTH = 10

  # The resolution values in degrees for each position in the lat/lng pair
  # encoding. These give the place value of each position, and therefore the
  # dimensions of the resulting area.
  PAIR_RESOLUTIONS = [20.0, 1.0, 0.05, 0.0025, 0.000125]

  # Number of columns in the grid refinement method.
  GRID_COLUMNS = 4

  # Number of rows in the grid refinement method.
  GRID_ROWS = 5

  # Size of the initial grid in degrees.
  GRID_SIZE_DEGREES = 0.000125

  # Minimum length of a code that can be shortened.
  MIN_TRIMMABLE_CODE_LEN = 6

  #Returns the OLC alphabet.
  def alphabet
    CODE_ALPHABET
  end

  OLCError = Class.new(StandardError)

  # Clip a latitude into the range -90 to 90.
  def clip_latitude(latitude)
    [ 90, [-90, latitude].max ].min
  end

  # Normalize a longitude into the range -180 to 180, not including 180.
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
  def compute_latitude_precision(code_length)
    if code_length <= 10
      return 20**(code_length/-2.0 + 2).floor
    end

    (20**-3).to_f/GRID_ROWS**(code_length - 10)
  end

  def encode(latitude, longitude, code_length = PAIR_CODE_LENGTH)
    if code_length < 2 || (code_length < SEPARATOR_POSITION && code_length % 2 == 1)
      raise OLCError, 'Invalid Open Location Code length'
    end

    # Ensure that latitude and longitude are valid.
    latitude = clip_latitude(latitude)
    longitude = normalize_longitude(longitude)

    # Latitude 90 needs to be adjusted to be just less, so the returned code
    # can also be decoded.
    if latitude == 90
      latitude -= compute_latitude_precision(code_length)
    end

    code = encode_pairs(latitude, longitude, [code_length, PAIR_CODE_LENGTH].min)

    # If the requested length indicates we want grid refined codes.
    if code_length > PAIR_CODE_LENGTH
      code += encode_grid(latitude, longitude, code_length - PAIR_CODE_LENGTH)
    end

    code
  end

  def encode_pairs(latitude, longitude, code_length)
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
  def encode_grid(latitude, longitude, code_length)
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
  #  Decodes an Open Location Code into the location coordinates.
  #
  #  Returns a CodeArea object that includes the coordinates of the bounding
  #  box - the lower left, center and upper right.
  #
  #  Args:
  #    code: The Open Location Code to decode.
  #
  #  Returns:
  #    A CodeArea object that provides the latitude and longitude of two of the
  #    corners of the area, the center, and the length of the original code.
  #
  def decode(code)
    unless full?(code)
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
      code_area.code_length + grid_area.code_length)
  end

  #
  #  Decode an OLC code made up of lat/lng pairs.
  #
  #  This decodes an OLC code made up of alternating latitude and longitude
  #  characters, encoded using base 20.
  #
  #  Args:
  #    code: A valid OLC code, presumed to be full, but with the separator
  #    removed.
  #
  def decode_pairs(code)
    # Get the latitude and longitude values. These will need correcting from
    # positive ranges.

    latitude = decode_pairs_sequence(code, 0)
    longitude = decode_pairs_sequence(code, 1)

    # Correct the values and set them into the CodeArea object.
    return CodeArea.new(
        latitude[0] - LATITUDE_MAX,
        longitude[0] - LONGITUDE_MAX,
        latitude[1] - LATITUDE_MAX,
        longitude[1] - LONGITUDE_MAX,
        code.length)
  end

  #
  #  Decode either a latitude or longitude sequence.
  #
  #  This decodes the latitude or longitude sequence of a lat/lng pair encoding.
  #  Starting at the character at position offset, every second character is
  #  decoded and the value returned.
  #
  #  Args:
  #    code: A valid OLC code, presumed to be full, with the separator removed.
  #    offset: The character to start from.
  #
  #  Returns:
  #    A pair of the low and high values. The low value comes from decoding the
  #    characters. The high value is the low value plus the resolution of the
  #    last position. Both values are offset into positive ranges and will need
  #    to be corrected before use.
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
  #  Args:
  #    code: A valid OLC code sequence that is only the grid refinement
  #        portion. This is the portion of a code starting at position 11.
  #
  def decode_grid(code)
    latitude_lo = 0.0
    longitude_lo = 0.0
    lat_place_value = GRID_SIZE_DEGREES
    lng_place_value = GRID_SIZE_DEGREES

    (code.length - 1).times do |i|
      code_index = CODE_ALPHABET.index(code[i])
      row = (code_index.to_f / GRID_COLUMNS).floor
      col = code_index % GRID_COLUMNS

      lat_place_value /= GRID_ROWS
      lng_place_value /= GRID_COLUMNS

      latitude_lo += row * lat_place_value
      longitude_lo += col * lng_place_value
    end

    CodeArea.new(
        latitude_lo, longitude_lo, latitude_lo + lat_place_value,
        longitude_lo + lng_place_value, code.length)
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
  def full?(code)
    return false unless valid?(code)

    # If it's short, it's not full.
    return false if short?(code)

    # Work out what the first latitude character indicates for latitude.
    first_lat_value = CODE_ALPHABET.index( code[0].upcase) * ENCODING_BASE

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
  def valid?(code)
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
    code = code.sub(Regexp.new('\\' + SEPARATOR + '+'), '')
               .sub(Regexp.new(PADDING_CHARACTER + '+'), '')

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
  def short?(code)
    # Check it's valid.
    return false unless valid?(code)

    # If there are less characters than expected before the SEPARATOR.
    separator_index = code.index(SEPARATOR).to_i

    if separator_index >= 0 && separator_index < SEPARATOR_POSITION
      return true
    end

    return false
  end
end
