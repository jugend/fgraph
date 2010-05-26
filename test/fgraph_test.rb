require 'test_helper'

class FGraphTest < Test::Unit::TestCase
  FACEBOOK_APP_ID = '112157085578818'
  FACEBOOK_APP_SECRET = '41f0e7ee8b6501dca1610de9926477c4'
  FACEBOOK_OAUTH_REDIRECT_URI = 'http://www.example.com/oauth_redirect'
  FACEBOOK_OAUTH_CODE = '2.0eXhebBSDTpoe08qIaocNQ__.3600.1273748400-503153225|caqygNb5Gobz6lpj3HXjlthDxds.'
  FACEBOOK_OAUTH_ACCESS_TOKEN = "115187085478818|rDIv_5zgjCSM_fWBv5Z-lQr5gFk."
  FACEBOOK_OAUTH_APP_ACCESS_TOKEN = "112167085478818|rDIv_5zgjCSM_fWBv5Z-lQr5gFk."
  
  context "FGraph.get_id" do
    should "return 'id' if input 'id' is not a Hash" do
      test_id = '123'
      id = FGraph.get_id(test_id)
      id.should == test_id
    end
    
    should "return 'id' value from hash object if input 'id' is a Hash" do
      test_id = { 'name' => 'Anthony', 'id' => '123' }
      id = FGraph.get_id(test_id)
      id.should == test_id['id']
    end
  end
  
  context "FGraph.object" do
    should "return object hash" do
      stub_get('/cocacola', 'object_cocacola.json')
      object = FGraph.object('cocacola')
      
      object.should_not be_nil
      object['name'].should == 'Coca-Cola'
    end
    
    should "call handle_response" do
      stub_get('/cocacola', 'object_cocacola.json')
      FGraph.expects(:handle_response).once
      object = FGraph.object('cocacola')
    end
    
    should "parse options into get options" do
      options = {:fields => 'id,name,picture'}
      FGraph.expects(:perform_get).with('/cocacola', options)
      FGraph.object('cocacola', options)
    end
    
    should "call FGraph.get_id" do
      stub_get('/cocacola', 'object_cocacola.json')
      FGraph.expects(:get_id).with('cocacola')
      FGraph.expects(:perform_get)
      object = FGraph.object('cocacola')
    end
  end
  
  context "FGraph.objects" do
    should "call perform_get with ids and query options" do
      options = {:fields => 'id,name'}
      FGraph.expects(:perform_get).with('/', options.merge(:ids => '1,2'))
      FGraph.objects('1', '2', options)
    end
    
    should "collect id values if input is an array of hash values" do
      test_ids = [
        { 'name' => 'Herry', 'id' => '1'},
        { 'name' => 'John', 'id' => '2'}
      ]
      FGraph.expects(:perform_get).with('/', :ids => '1,2')
      FGraph.objects(test_ids)
    end
  end
  
  context "FGraph.me" do
    access_token = {:access_token => FACEBOOK_OAUTH_ACCESS_TOKEN}
    
    should "get object with /me path" do
      FGraph.expects(:object).with('me', access_token)
      FGraph.me(access_token)
    end
    
    should "get object with /me/likes path" do
      FGraph.expects(:object).with('me/likes', access_token)
      FGraph.me('likes', access_token)
    end
  end
  
  context "FGraph.oauth_authorize_url" do
    should "should call format_url with appropriate hash" do
      FGraph.expects(:format_url).with('/oauth/authorize', {
        :client_id => FACEBOOK_APP_ID,
        :redirect_uri => FACEBOOK_OAUTH_REDIRECT_URI
      })
      
      FGraph.oauth_authorize_url(FACEBOOK_APP_ID, FACEBOOK_OAUTH_REDIRECT_URI)
    end
    
    should "should call format_url with options" do
      FGraph.expects(:format_url).with('/oauth/authorize', {
        :client_id => FACEBOOK_APP_ID,
        :redirect_uri => FACEBOOK_OAUTH_REDIRECT_URI,
        :scope => 'publish_stream'
      })
      
      FGraph.oauth_authorize_url(FACEBOOK_APP_ID, FACEBOOK_OAUTH_REDIRECT_URI,
        :scope => 'publish_stream')
    end
  end
  
  context "FGraph.oauth_access_token" do
    should "return user access token and expires" do
      stub_get(FGraph.format_url('/oauth/access_token', {
        :client_id => FACEBOOK_APP_ID,
        :client_secret => FACEBOOK_APP_SECRET,
        :redirect_uri => FACEBOOK_OAUTH_REDIRECT_URI,
        :code => FACEBOOK_OAUTH_CODE
      }), 'access_token.txt')
      
      token = FGraph.oauth_access_token(FACEBOOK_APP_ID, FACEBOOK_APP_SECRET, 
        :redirect_uri => FACEBOOK_OAUTH_REDIRECT_URI, 
        :code => FACEBOOK_OAUTH_CODE)
      
      token['access_token'].should == 'thisisanaccesstoken'
      token['expires'].should == '4000'
    end
  end
  
  context "FGraph.publish" do
    options = { :message => 'test message'}
      
    should "call perform_post" do
      FGraph.expects(:perform_post).with("/me/feed", options)
      FGraph.publish('me/feed', options)
    end
    
    should "have publish_[category] method" do
      FGraph.expects(:publish).with('me/feed', options)
      FGraph.publish_feed('me', options)
    end
  end
  
  context "FGraph.delete" do
    options = {}

    should "call perform_delete" do
      FGraph.expects(:perform_delete).with('/12345', options)
      FGraph.remove('12345', options)
    end
    
    should "support remove_[category] method" do
      FGraph.expects(:remove).with('12345/likes', options)
      FGraph.remove_likes('12345', options)
    end
  end
  
  context "FGraph.search" do
    should "call perform_get('/search')" do
      FGraph.expects(:perform_get).with('/search', {
        :q => 'watermelon',
        :type => 'post'
      })
      
      FGraph.search('watermelon', :type => 'post')
    end
    
    should "support dynamic method search_[type] method" do
      FGraph.expects(:search).with('watermelon', {
        :type => 'post'
      })
      
      FGraph.search_post('watermelon')
    end
  end
  
  context "Facebook.insights" do
    should "call perform_get('/[client_id]/insights')" do
      FGraph.expects(:perform_get).with("/#{FACEBOOK_APP_ID}/insights", {
        :access_token => FACEBOOK_OAUTH_APP_ACCESS_TOKEN
      })
      
      FGraph.insights(FACEBOOK_APP_ID, FACEBOOK_OAUTH_APP_ACCESS_TOKEN)
    end
    
    should "process :metric_path option" do
      FGraph.expects(:perform_get).with("/#{FACEBOOK_APP_ID}/insights/application_api_call/day", {
        :access_token => FACEBOOK_OAUTH_APP_ACCESS_TOKEN
      })
      
      FGraph.insights(FACEBOOK_APP_ID, FACEBOOK_OAUTH_APP_ACCESS_TOKEN, {
        :metric_path => 'application_api_call/day'
      })
    end
  end
  
  context "FGraph.method_missing" do
    options = options = {:filter => 'id,name,picture'}
    
    should "auto map object_[category] method" do
      FGraph.expects(:object).with('arun/photos', options)
      FGraph.object_photos('arun', options)
    end
    
    should "auto map me_[category] method" do
      FGraph.expects(:me).with('photos', options)
      FGraph.me_photos(options)
    end
    
    should "raise no method error if missing method name does not start with object_ or me_" do
      lambda do
        FGraph.xyz_photos
      end.should raise_error(NoMethodError)
    end
  end
  
  context "FGraph.format_url" do
    should "return URL without query string" do
      formatted_url = FGraph.format_url('/test')
      formatted_url.should == "https://graph.facebook.com/test"
    end
    
    should "return URL with query string with escaped value" do
      formatted_url = FGraph.format_url('/test',  {:username => 'john lim'})
      formatted_url.should == "https://graph.facebook.com/test?username=john+lim"
    end

    should "return URL with multiple options" do
      formatted_url = FGraph.format_url('/test', {:username => 'john', :age => 20})
      formatted_url.should =~ /username=john/
      formatted_url.should =~ /age=20/
      formatted_url.should =~ /&/
    end

    should "return URL without empty options" do
      formatted_url = FGraph.format_url('/test', {:username => 'john', :age => nil})
      formatted_url.should == "https://graph.facebook.com/test?username=john"
    end
  end
  
  context "FGraph.handle_response" do
    should "return response object if there's no error" do
      fb_response = {'name' => 'test'}
      response = FGraph.handle_response(fb_response)
      response.should == fb_response
    end
    
    should "convert to FGraph::Collection object if response contain 'data' value" do
      fb_response = {
        "data" => [
          { "name" =>"Belle Clara", "id" => "100000133774483" },
          { "name" =>"Rosemary Schapira", "id" => "100000237306697" }
        ],
        "paging" => {
          "next" => "https://graph.facebook.com/756314021/friends?offset=4&limit=2&access_token=101507589896698"
        }
      }
      
      collection = FGraph.handle_response(fb_response)
      collection.class.should == FGraph::Collection
      collection.count.should == fb_response['data'].count
    end
    
    should "raise QueryParseError" do
      lambda do
        object = FGraph.handle_response(response_error('QueryParseException'))
      end.should raise_error(FGraph::QueryParseError)
    end
    
    should "raise GraphMethodError" do
      lambda do
        object = FGraph.handle_response(response_error('GraphMethodException'))
      end.should raise_error(FGraph::GraphMethodError)
    end
    
    should "raise OAuthError" do
      lambda do
        object = FGraph.handle_response(response_error('OAuthException'))
      end.should raise_error(FGraph::OAuthError)
    end
    
    should "raise OAuthAccessTokenError" do
      lambda do
        object = FGraph.handle_response(response_error('OAuthAccessTokenException'))
      end.should raise_error(FGraph::OAuthAccessTokenError)
    end
  end
  
  context "FGraph::Collection" do
    should "should convert response object to Collection" do
      response = {
        "data" => [
          {"name"=>"Belle Clara", "id"=>"100000133774483"},
          {"name"=>"Rosemary Schapira", "id"=>"100000237306697"}
        ],
        "paging"=> {
          "previous"=> "https://graph.facebook.com/756314021/friends?offset=0&limit=2&access_token=101507589896698",
          "next"=> "https://graph.facebook.com/756314021/friends?offset=4&limit=2&access_token=101507589896698"
        }
      }
      
      collection = FGraph::Collection.new(response)
      collection.count.should == response['data'].count
      collection.first.should == response['data'].first
      collection.next_url.should == response['paging']['next']
      collection.previous_url.should == response['paging']['previous']
      collection.previous_options.should == {'offset' => '0', 'limit' => '2', 'access_token' => '101507589896698'}
      collection.next_options.should == {'offset' => '4', 'limit' => '2', 'access_token' => '101507589896698'}
    end
  end
  
  def response_error(type, msg=nil)
    {'error' => { 'type' => type, 'message' => msg}}
  end
end
