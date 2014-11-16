require 'spec_helper'
require 'json'

RSpec.describe 'The Simple Tor Relay App', feature: true do
  let(:installer) {
    installer = Installer.new("https://github.com/fake/project")
    installer.region = 'NYC3'
    installer.size = '512mb'
    installer.config = { size: installer.size, region: installer.region }
    installer.droplet_id = 'FAKE_ID'
    installer
  }

  specify "the main page has content" do
    get '/'
    expect(last_response).to be_ok
    expect(last_response.body).to include('Simple Tor Relay')
  end

  specify "the install page has content" do
    get '/install'
    expect(last_response).to be_ok
    expect(last_response.body).to include('Set-up Tor node')
  end

  specify "the status page returns the status" do
    get '/status'
    expect(last_response).to be_ok
    expect(last_response.body).to include('Status')
  end

  specify "GET to /auth/callback calls installer and redirects to status" do
    expect(Installer).to receive(:from_json){ installer }
    expect(installer).to receive(:auth_token=).with("FAKE_TOKEN")
    expect(installer).to receive(:go!)

    get '/auth/callback'

    expect(last_response).to be_redirect
    follow_redirect!
    expect(last_request.env['PATH_INFO']).to eq('/status')
  end

  specify "POST to /install with no current session redirects to authorize" do
    installer  
    expect(Installer).to receive(:new) { installer }

    post '/install'
    expect(last_response).to be_redirect
    follow_redirect!
    expect(last_request.env['PATH_INFO']).to eq('/v1/oauth/authorize')
  end


  specify "POST to /install with invalid session redirects to authorize" do
    installer
    expect(Installer).to receive(:new) { installer }
    expect(installer).to receive(:auth_token) { "FAKE_TOKEN" }
    expect(installer).to receive(:go!) { raise RestClient::Unauthorized }

    post '/install'
    expect(last_response).to be_redirect
    follow_redirect!
    expect(last_request.env['PATH_INFO']).to eq('/v1/oauth/authorize')
  end

  specify "POST to /install with existing session redirects to status" do
    installer
    expect(Installer).to receive(:new) { installer }
    expect(installer).to receive(:auth_token) { "FAKE_TOKEN" }
    expect(installer).to receive(:go!)


    post '/install'
    expect(last_response).to be_redirect
    follow_redirect!
    expect(last_request.env['PATH_INFO']).to eq('/status')
  end  

end
