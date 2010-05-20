# Replace FACEBOOK_ACCESS_TOKEN with valid token with publish_stream extended permission
#
# Post to user's feed.
#   curl -F 'access_token=...' -F 'message=Hello, Arjun. I like this new API.' https://graph.facebook.com/me/feed
# curl -F 'access_token=112157085478818|2.AlP5TBjZ9F6wOXPX_V0GTg__.3600.1273777200-756314021|NV7Dnuol59KbQr6W1axv6ZmytaI.' -F 'message=Hello, Arjun. I like this new API.' https://graph.facebook.com/me/feed
FACEBOOK_ACCESS_TOKEN = '112157085478818|2.Dq5RDPHxhsgaeScc_fiigg__.3600.1273831200-756314021|Tvm41skDwOdGR2O3Lz4owMVz1lM.'

require 'rubygems'
require 'pp'
require File.dirname(__FILE__) + '/../lib/fgraph'

# Post to current user's f eed
pp FGraph.publish_feed('me', :message => 'Hello. I like this new API.', 
  :access_token => FACEBOOK_ACCESS_TOKEN)
  
puts "Message successfully posted."