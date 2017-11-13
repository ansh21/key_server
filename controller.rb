require 'sinatra'
require 'json'
require_relative 'key_server'

key_server = KeyServer.new

Thread.new do
  loop do
    sleep 1
    key_server.cleanup
  end
end

get '/' do
  'OK'
end

# generate keys
get '/keys/generate' do
  keys = key_server.generate_key(5)
  keys.join('<br/>')
end

# get available keys
get '/keys/available/all' do
  content_type :json
  key_server.available_keys.to_json
end

# get all keyss
get '/keys/all' do
  content_type :json
  key_server.keys.to_json
end

# get an available key
get '/keys/available' do
  key = key_server.get_key
  if key.nil?
    status 404
    body 'No key is available'
  else
    status 200
    body key
  end
end

# unblock a key
get '/keys/unblock/:id' do |key|
  if !key_server.unblock_key(key)
    status 404
    "No key #{key} found"
  else
    status 200
    "Key: #{key} Unblocked"
  end
end

# delete a key
get '/keys/delete/:id' do |key|
  if !key_server.delete_key(key)
    status 404
    "No key #{key} found"
  else
    status 200
    "Key : #{key} Deleted"
  end
end

# keep alive key
get '/keys/keepalive/:id' do |key|
  if !key_server.keep_alive_key(key)
    status 404
    "No key #{key} found"
  else
    status 200
    "Keep alive successful for #{key}"
  end
end
