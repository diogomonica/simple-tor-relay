require 'spec_helper'

RSpec.describe 'The installer' do
  let(:installer) {
    installer = Installer.new("https://github.com/fake/project")
    installer.region = 'NYC3'
    installer.size = '512mb'
    installer.config = { size: installer.size, region: installer.region }
    installer.droplet_id = 'FAKE_ID'
    installer
  }

  specify "go! calls the right API" do
    allow(installer).to receive(:payload_for_deploy) { {} }
    expect(installer.go!).to eq(3164494)
  end

  specify "droplet_info gets the right data" do
    installer.droplet_id = 3164494
    installer.droplet_info
    expect(installer.droplet_status).to eq('active')
    expect(installer.droplet_ip).to eq('104.131.186.241')
  end
end
