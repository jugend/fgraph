require 'test_helper'

class ClientTest < Test::Unit::TestCase
  FACEBOOK_API_KEY = '878116c4a4b79f25e4beb97ab096cc92'
  FACEBOOK_APP_SECRET = '41f0e7ee8b6501dca1610de9926477c4'
  FACEBOOK_APP_ID = '112157085578818'
  FACEBOOK_OAUTH_REDIRECT_URI = 'http://www.example.com/oauth_redirect'
  FACEBOOK_OAUTH_CODE = '2.0eXhebBSDTpoe08qIaocNQ__.3600.1273748400-503153225|caqygNb5Gobz6lpj3HXjlthDxds.'
  FACEBOOK_OAUTH_ACCESS_TOKEN = "115187085478818|rDIv_5zgjCSM_fWBv5Z-lQr5gFk."
  FACEBOOK_OAUTH_APP_ACCESS_TOKEN = "112167085478818|rDIv_5zgjCSM_fWBv5Z-lQr5gFk."
  
  def fb_client
    FGraph::Client.new(
      :client_id => FACEBOOK_API_KEY,
      :client_secret => FACEBOOK_APP_SECRET,
      :access_token => FACEBOOK_OAUTH_ACCESS_TOKEN
    )
  end
  
  context "FGraph::Client#oauth_authorize_url" do
    should "call FGraph.oauth_authorize_url with :client_id option" do
      FGraph.expects(:oauth_authorize_url).with(FACEBOOK_API_KEY, FACEBOOK_OAUTH_REDIRECT_URI)
      fb_client.oauth_authorize_url(FACEBOOK_OAUTH_REDIRECT_URI)
    end
  end
  
  context "FGraph::Client#oauth_access_token" do
    should "call FGraph.oauth_access_token with :client_id and :client_secret options" do
      FGraph.expects(:oauth_access_token).with(FACEBOOK_API_KEY, FACEBOOK_APP_SECRET, 
        :redirect_uri => FACEBOOK_OAUTH_REDIRECT_URI, :code => FACEBOOK_OAUTH_CODE)
        
      fb_client.oauth_access_token(FACEBOOK_OAUTH_REDIRECT_URI, FACEBOOK_OAUTH_CODE)
    end
  end
  
  context "FGraph::Client#object" do
    should "call FGraph.object with :access_token option" do
      object_id = '12345'
      FGraph.expects(:object).with(object_id, 
        :access_token => FACEBOOK_OAUTH_ACCESS_TOKEN,
        :fields => 'user_photos'
      )
        
      fb_client.object(object_id, :fields => 'user_photos')
    end
    
    should "support #object_[category] method" do
      client = fb_client
      client.expects(:object).with('arun/photos', {:limit => 5})
      client.object_photos('arun', {:limit => 5})
    end
  end

  context "FGraph::Client#objects" do
    should "call FGraph.objects with :access_token option" do
      FGraph.expects(:objects).with(['1', '2', {
        :access_token => FACEBOOK_OAUTH_ACCESS_TOKEN, 
        :fields => 'user_photos'
      }])
      
      fb_client.objects('1', '2', :fields => 'user_photos')
    end
  end
  
  context "FGraph::Client#me" do
    should "call FGraph.me with :access_token option" do
      FGraph.expects(:me).with([{
        :access_token => FACEBOOK_OAUTH_ACCESS_TOKEN, 
        :fields => 'user_photos'
      }])
      
      fb_client.me(:fields => 'user_photos')
    end
    
    should "support #me_[category] method" do
      client = fb_client
      client.expects(:me).with('photos', {:limit => 5})
      client.me_photos(:limit => 5)
    end
  end
  
  context "FGraph::Client#publish" do
    should "call FGraph.publish with :access_token option" do
      id = '1'
      FGraph.expects(:publish).with(id, {
        :access_token => FACEBOOK_OAUTH_ACCESS_TOKEN, 
        :message => 'hello'
      })
      
      fb_client.publish(id, :message => 'hello')
    end
    
    should "support publish_[category] method" do
      client = fb_client
      client.expects(:publish).with('me/feed', {:limit => 5})
      client.publish_feed('me', {:limit => 5})
    end
  end
  
  context "FGraph::Client#remove" do
    should "call FGraph.remove with :access_token option" do
      id = '1'
      FGraph.expects(:remove).with(id, {
        :access_token => FACEBOOK_OAUTH_ACCESS_TOKEN
      })
      
      fb_client.remove(id)
    end
    
    should "support remove_[category] method" do
      client = fb_client
      client.expects(:remove).with('12345/likes', {:limit => 5})
      client.remove_likes('12345', :limit => 5)
    end
  end
  
  context "FGraph::Client#search" do
    should "call FGraph.search with options" do
      query = 'watermelon'
      options = {:limit => 5}
      FGraph.expects(:search).with(query, options)
      
      fb_client.search(query, options)
    end
    
    should "support dynamic method search_[type] method" do
      client = fb_client
      client.expects(:search).with('watermelon', {
        :type => 'post'
      })
      client.search_post('watermelon')
    end
  end
  
  context "FGraph::Client#insights" do
    should "auto populate :app_id and :oauth_app_access_token" do
      client = fb_client 
      client.options[:app_id] = FACEBOOK_APP_ID
      client.options[:app_access_token] = FACEBOOK_OAUTH_APP_ACCESS_TOKEN
      
      FGraph.expects(:insights).with(FACEBOOK_APP_ID, FACEBOOK_OAUTH_APP_ACCESS_TOKEN, {})
      client.insights
    end
    
    should "auto retrieve :oauth_app_access_token option" do
      client = fb_client
      
      client.expects(:oauth_app_access_token).returns(FACEBOOK_OAUTH_APP_ACCESS_TOKEN)
      FGraph.expects(:insights).with(nil, FACEBOOK_OAUTH_APP_ACCESS_TOKEN, {
        :metric_path => 'application_api_calls/day'
      })
      client.insights(:metric_path => 'application_api_calls/day')
    end
  end
end