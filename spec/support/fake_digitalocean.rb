require 'sinatra/base'

class FakeDigitalOcean < Sinatra::Base
  post '/v2/droplets' do
    json_response 200, 'droplet.json'
  end

  get '/v2/droplets' do
    json_response 200, 'droplets.json'
  end

  get '/v2/droplets/:droplet_id' do
    json_response 200, 'droplet.json'
  end

  get '/v2/account/keys' do
    json_response 200, 'keys.json'
  end

  private

  def json_response(response_code, file_name)
    content_type :json
    status response_code
    File.read(File.dirname(__FILE__) + '/fixtures/' + file_name)
  end
end
