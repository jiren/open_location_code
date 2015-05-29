$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'open_location_code'
require 'csv'

SPEC_DIR = File.expand_path(File.dirname(__FILE__))

def fixture_file(name)
  "#{SPEC_DIR}/fixtures/#{name}"
end

def test_data(file_name)
  csv = CSV.open(fixture_file(file_name))
  csv.readlines.select{|l| l[0][0] != '#'}
end
