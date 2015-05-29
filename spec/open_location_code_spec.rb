require 'spec_helper'

describe OpenLocationCode do

  let(:encoding_data) { test_data('encodingTests.csv') }

  it 'has a version number' do
    expect(OpenLocationCode::VERSION).not_to be nil
  end

  it 'encode lat lon to code' do
    code = OpenLocationCode.encode(47.365590, 8.524997, 12)
    expect(code).to eq('8FVC9G8F+6XQH')
  end

  it 'decode code to lat lng' do
    code_area = OpenLocationCode.decode('8FVC9G8F+6XQH')

    expect(code_area.latitude_center).to eq(47.36558749999997)
    expect(code_area.longitude_center).to eq(8.524996093750008)
  end

  it 'validates encoder' do
    encoding_data.each do |data|
      code = data[0]
      lat = data[1].to_f
      lng = data[2].to_f

      code_length = code.length - 1

      expect(OpenLocationCode.encode(lat, lng, code_length)).to eq code
    end
  end

end
