module OpenLocationCode
  class CodeArea
    attr_accessor :latitude_lo, :longitude_lo, :latitude_hi, :longitude_hi
    attr_accessor :latitude_center, :longitude_center, :code_length

    def initialize(latitude_lo, longitude_lo, latitude_hi, longitude_hi, code_length)
      @latitude_lo  = latitude_lo
      @longitude_lo = longitude_lo
      @latitude_hi  = latitude_lo
      @longitude_hi = longitude_hi
      @code_length  = code_length

      set_center
    end

    def set_center
      @latitude_center = [ latitude_lo + (latitude_hi - latitude_lo) / 2.0, LATITUDE_MAX].min
      @longitude_center = [ longitude_lo + (longitude_hi - longitude_lo)/ 2.0, LONGITUDE_MAX].min
    end
  end
end
