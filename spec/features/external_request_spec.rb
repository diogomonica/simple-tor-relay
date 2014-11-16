require 'spec_helper'

RSpec.describe 'External request', feature: true do
  it 'tries to query digital oceans API' do
    uri = URI('https://api.digitalocean.com/v2/droplets')

    response = Net::HTTP.get(uri)

    expect(response).to be_an_instance_of(String)
  end
end
