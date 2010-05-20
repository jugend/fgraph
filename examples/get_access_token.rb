# Retrieve your code by accessing Authorization URL From your browser, 
# it should redirect to 'redirect_uri' with 'code' param.
# Replace the FACEBOOK_XXX constants accordingly.
#
# Authorization URL, access from your browser to get Authorization Code
# https://graph.facebook.com/oauth/authorize?client_id=878116c4a4a76f25e4beb97ab096cc92&redirect_uri=http%3A%2F%2Fbookjetty.pluitsolutions.com%2F&scope=publish_stream

FACEBOOK_APP_ID = '878116c4a4a76f25e4beb97ab096cc92'
FACEBOOK_APP_SECRET = '41f0e7ee8b6409dce1610de9926477c4'
FACEBOOK_OAUTH_REDIRECT_URI = 'http://bookjetty.pluitsolutions.com/'
FACEBOOK_OAUTH_CODE = '2.Dq5RDPHxhsgaeScc_fiigg__.3600.1273831200-756314021|4Eew6iuIg0x69N1d3Cr99gdVGwU.'
FACEBOOK_OAUTH_SCOPE = ''

require 'pp'
require 'rubygems'
require File.dirname(__FILE__) + '/../lib/fgraph'

pp FGraph.oauth_access_token(FACEBOOK_APP_ID, FACEBOOK_OAUTH_REDIRECT_URI,
  FACEBOOK_APP_SECRET, FACEBOOK_OAUTH_CODE)