require 'spec_helper'

describe OpenLocationCode do
  it 'has a version number' do
    expect(OpenLocationCode::VERSION).not_to be nil
  end

  it 'encode lat lon to code' do
    code = OpenLocationCode.encode(47.365590, 8.524997, 12)
    expect(code).to eq('8FVC9G8F+6XQH')
  end

  it 'decode code to lat lng' do
    code_area = OpenLocationCode.decode('8FVC9G8F+6XQH')

    expect(code_area.latitude_center).to eq(47.36557499999997)
    expect(code_area.longitude_center).to eq(8.52498437500001)
  end
end
