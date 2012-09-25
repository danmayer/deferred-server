get '/' do
  "Hello World!"
end

post '/' do
   push = JSON.parse(params[:payload])
   "I got some JSON: #{push.inspect}"
end

def start_server
  compute = Fog::Compute.new(
                             :provider          => 'AWS',
                             :aws_access_key_id => ENV['AMAZON_ACCESS_KEY_ID'],
                             :aws_secret_access_key => ENV['AMAZON_SECRET_ACCESS_KEY'])

  compute.servers.create(:image_id => 'ami-0267bb6b',
                         :name => 'wakeup-hook-responder')
  #now wait for server and hit a api endpoint
end
