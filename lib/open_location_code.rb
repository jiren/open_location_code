require 'open_location_code/version'
require 'open_location_code/code_area'
require 'open_location_code/encoder'
require 'open_location_code/decoder'

#
# Example:
#
#   # Encode a location, default accuracy:
#   code = OpenLocationCode.encode(47.365590, 8.524997) # 8FVC9G8F+6X
#
#   # Encode a location using one stage of additional refinement:
#   code = OpenLocationCode.encode(47.365590, 8.524997, 11) # 8FVC9G8F+6XQ
#
#   # Decode a full code:
#   coord = OpenLocationCode.decode(code)
#
module OpenLocationCode

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

  # Error class
  OLCError = Class.new(StandardError)

  #
  # OLC alphabet.
  # @return [String]
  #
  def self.alphabet
    CODE_ALPHABET
  end

  #
  #  Encode a location into an Open Location Code.
  #
  #  Produces a code of the specified length, or the default length if no length
  #  is provided.
  #
  #  The length determines the accuracy of the code. The default length is
  #  10 characters, returning a code of approximately 13.5x13.5 meters. Longer
  #  codes represent smaller areas, but lengths > 14 are sub-centimetre and so
  #  11 or 12 are probably the limit of useful codes.
  #
  # @param [Float] latitude
  #   A latitude in signed decimal degrees. Will be clipped to the range -90 to 90.
  # @param [Float] longitude
  #   A longitude in signed decimal degrees. Will be normalised to the range -180 to 180.
  # @param [Integer] code_length
  #   The number of significant digits in the output code, not including any separator characters.
  # @return [String]
  #   Encoded code
  def self.encode(latitude, longitude, code_length = nil)
    Encoder.new(latitude, longitude, code_length || PAIR_CODE_LENGTH).process
  end

  #
  #  Decodes an Open Location Code into the location coordinates.
  #
  # @param [String] code
  #   The Open Location Code to decode.
  # @return [CodeArea]
  #   An object that provides the latitude and longitude of two of the
  #   corners of the area, the center, and the length of the original code.
  def self.decode(code)
    Decoder.new(code).process
  end

end
