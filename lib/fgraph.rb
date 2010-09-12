require 'httparty'
require 'cgi'
require 'fgraph/client'

module FGraph
  include HTTParty
  base_uri 'https://graph.facebook.com'
  format :json
  
  # Facebook Error
  class FacebookError < StandardError
    attr_reader :data
    
    def initialize(data)
      @data = data
      super("(#{data['type']}) #{data['message']}")
    end
  end
  
  class QueryParseError < FacebookError; end
  class GraphMethodError < FacebookError; end
  class OAuthError < FacebookError; end
  class OAuthAccessTokenError < OAuthError; end
  
  # Collection objects for Graph response with array data.
  #
  class Collection < Array 
    attr_reader :next_url, :previous_url, :next_options, :previous_options
    
    # Initialize Facebook response object with 'data' array value.
    def initialize(response)
      return super unless response
      
      super(response['data'])
      paging = response['paging'] || {}
      self.next_url = paging['next']
      self.previous_url = paging['previous']
    end
    
    def next_url=(url)
      @next_url = url
      @next_options = self.url_options(url)
    end
    
    def previous_url=(url)
      @previous_url = url
      @previous_options = self.url_options(url)
    end
    
    def first?
      @previous_url.blank? and not @next_url.blank?
    end
    
    def next?
      not @next_url.blank?
    end
    
    def previous?
      not @previous_url.blank?
    end
    
    def url_options(url)
      return unless url
      
      uri = URI.parse(url)
      options = {}
      uri.query.split('&').each do |param_set|
         param_set = param_set.split('=')
         options[param_set[0]] = CGI.unescape(param_set[1])
      end
      options
    end
  end
  
  class << self
    attr_accessor :config
    
    # Single object query.
    # 
    #   # Users: https://graph.facebook.com/btaylor  (Bret Taylor)
    #   FGraph.object('btaylor')
    #
    #   # Pages: https://graph.facebook.com/cocacola (Coca-Cola page)
    #   FGraph.object('cocacola')
    #
    #   # Fields selection with metadata
    #   FGraph.object('btaylor', :fields => 'id,name,picture', :metadata => 1)
    #
    #   # Page photos
    #   FGraph.object('/cocacola/photos')
    #   photos = FGraph.object_photos('cocacola')
    #   
    #   # Support id from object hash
    #   friend = { 'name' => 'Mark Zuckerberg', 'id' => '4'}
    #   friend_details = FGraph.object(friend)
    def object(id, options={})
      id = self.get_id(id)
      perform_get("/#{id}", options)
    end
  
    # call-seq:
    #   FGraph.objects(id, id)
    #   FGraph.objects(id, id, options_hash)
    #
    # Multiple objects query.
    # 
    #   # Multiple users select: https://graph.facebook.com?ids=arjun,vernal
    #   FGraph.objects('arjun', 'vernel')
    #
    #   # Filter fields: https://graph.facebook.com?ids=arjun,vernal&fields=id,name,picture
    #   FGraph.objects('arjun', 'vernel', :fields => 'id,name,picture')
    #
    def objects(*args)
      options = args.last.is_a?(Hash) ? args.pop : {}
    
      # If first input before option is an array
      if args.length == 1 and args.first.is_a?(Array)
        args = args.first.map do |arg|
          self.get_id(arg)
        end
      end
    
      options = options.merge(:ids => args.join(','))
      perform_get("/", options)
    end
  
    # call-seq:
    #   FGraph.me(category)
    #   FGraph.me(category, options_hash)
    # 
    # Returns current user object details.
    # 
    # <tt>category</tt> - <tt>friends|home|feed|likes|movies|books|notes|photos|videos|events|groups</tt>
    #
    #   # Current user: https://graph.facebook.com/me?access_token=...
    #   FGraph.me(:access_token => '...')
    # 
    #   # Current user's friends: https://graph.facebook.com/me/friends?access_token=...
    #   FGraph.me('friends', :access_token => '...')
    #   FGraph.me_friends(:access_token => '...')
    #
    def me(*args)
      options = args.last.is_a?(Hash) ? args.pop : {}
      category = args.shift
    
      path = "me"
      path += "/#{category}" unless category.blank?
      self.object(path, options)
    end
  
    # Request authorization from Facebok to fetch private data in the profile or permission to publish on a
    # user's behalf. Returns Oauth Authorization URL, redirect to this URL to allow user to authorize your
    # application from Facebook.
    #
    # <tt>client_id</tt> - Application ID
    # <tt>redirect_uri</tt> - Needs to begin with your app's Connect URL. For instance, if your Connect URL 
    # is http://www.example.com then your redirect URI could be http://www.example.com/oauth_redirect.
    # <tt>scope (optional)</tt> -
    #
    # ==== Options
    # * <tt>scope</tt> -  Extended permission required to fetch private data or request permision to 
    # publish to Facebook on a user's behalf.
    # * <tt>display</tt> - Other display type for authentication/authorization form, i.e. popup, touch.
    #
    #   # https://graph.facebook.com/oauth/authorize?
    #   #   client_id=...&
    #   #   redirect_uri=http://www.example.com/oauth_redirect&
    #   #   scope=publish_stream
    #
    #   FGraph.oauth_authorize_url('[client id]', 'http://www.example.com/oauth_redirect', :scope => 
    #     'publish_stream')
    #
    def oauth_authorize_url(client_id, redirect_uri, options={})
      self.format_url('/oauth/authorize', {
        :client_id => client_id,
        :redirect_uri => redirect_uri
      }.merge(options))
    end
  
    # Return OAuth access_token. There are two types of access token, user access token and application 
    # access token.
    #
    # User access_token requires <tt>code</tt> and and <tt>redirect_uri</tt> options. <tt>code</tt> is
    # the autorization code appended as query string to redirect URI when accessing oauth authorization URL.
    #
    #   # https://graph.facebook.com/oauth/access_token?
    #   #   client_id=...&
    #   #   client_secret=...&
    #   #   redirect_uri=http://www.example.com/oauth_redirect&
    #   #   code=...
    #   FGraph.oauth_access_token('[client id]', '[client secret]', 
    #      :redirect_uri => ''http://www.example.com/oauth_redirect', 
    #      :code => '[authorization code]')
    #
    # Application access token requires <tt>:type => 'client_cred'</td> option. Used to access application
    # insights data.
    #
    #   # https://graph.facebook.com/oauth/access_token?
    #   #   client_id=...&
    #   #   client_secret=...&
    #   #   type=client_cred
    #   FGraph.oauth_access_token('[client id]', '[client secret]', :type => 'client_cred')
    #
    def oauth_access_token(client_id, client_secret, options={})
      url = self.format_url('/oauth/access_token', {
        :client_id => client_id,
        :client_secret => client_secret
      }.merge(options || {}))
    
      response = self.perform_get(url)
      response_hash = {}
      response.split('&').each do |value|
        value_pair = value.split('=')
        response_hash[value_pair[0]] = value_pair[1]
      end
      response_hash
    end
  
    # Shortcut to retrieve application access token.
    def oauth_app_access_token(client_id, client_secret)
      self.oauth_access_token(client_id, client_secret, :type => 'client_cred')
    end
  
    # Publish to Facebook, you would need to be authorized and provide access token.
    #
    #   # Post to user's feed.
    #   #   curl -F 'access_token=...' \
    #   #     -F 'message=Hello, Arjun. I like this new API.' \
    #   #     https://graph.facebook.com/arjun/feed
    #   FGraph.publish('arjun/feed', :message => 'Hello, Arjun. I like this new API.', 
    #     :access_token => '...')
    #   FGraph.publish_feed('arjun', :message => '...', :access_token => '...')
    #   FGraph.publish_feed('me', ':message => '...', :access_token => '...')
    #
    # ==== Options
    #
    #   Method                Description                             Options
    #   -------------------------------------------------------------------------------------
    #   /PROFILE_ID/feed      write to the given profile's feed/wall  :message, :picture, 
    #                                                                 :link, :name, description
    #   /POST_ID/comments     comment on the given post               :message
    #   /POST_ID/likes        like the given post                     none
    #   /PROFILE_ID/notes     write a note on the given profile       :message, :subject
    #   /PROFILE_ID/links     write a link on the given profile       :link, :message
    #   /EVENT_ID/attending   attend the given event                  none
    #   /EVENT_ID/maybe       maybe attend the given event            none
    #   /EVENT_ID/declined    decline the given event                 none
    # 
    def publish(id, options={})
      id = self.get_id(id)
      self.perform_post("/#{id}", options)
    end
  
    # Delete objects in the graph.
    #
    #   # DELETE https://graph.facebook.com/ID?access_token=... HTTP/1.1
    #   
    #   FGraph.remove('[ID]')
    #   FGraph.remove('[ID]/likes')
    #   FGraph.remove_likes('[ID]')
    #
    def remove(id, options={})
      id = self.get_id(id)
      self.perform_delete("/#{id}", options)
    end
  
    # Search over all public objects in the social graph.
    # 
    #   # https://graph.facebook.com/search?q=watermelon&type=post
    #   FGraph.search('watermelon', :type => 'post')
    #   FGraph.search_post('watermelon')
    #
    # ==== Options
    # * <tt>type</tt> - <tt>album|event|group|link|note|page|photo|post|status|user|video</tt>
    # * <tt>limit</tt> - max no of records
    # * <tt>offset</tt> - offset
    # * <tt>until</tt> - since (a unix timestamp or any date accepted by strtotime, e.g. yesterday)
    def search(query, options={})
      self.perform_get("/search", {
        :q => query
      }.merge(options|| {}))
    end
  
    # Download insights data for your application.
    #
    #   # https://graph.facebook.com/[client_id]/insights?access_token=...
    #   FGraph.insights('[client_id]', '[app_access_token]')
    #
    #   # https://graph.facebook.com/[client_id]/insights/application_api_call/day?access_token=...
    #   FGraph.insights('[client_id]', '[app_access_token]', :metric_path => 'application_api_call/day')
    # 
    # ==== Options
    # * <tt>metric_path</tt> - e.g. application_api_calls/day
    # * <tt>since</tt> - since (a unix timestamp or any date accepted by strtotime, e.g. yesterday)
    # * <tt>until</tt> - until (a unix timestamp or any date accepted by strtotime, e.g. yesterday)
    def insights(client_id, app_access_token, options={})
      metric_path = options.delete(:metric_path)
    
      path = "/#{client_id}/insights"
      path += "/#{metric_path}" if metric_path
      
      self.perform_get(path, {
        :access_token => app_access_token
      }.merge(options || {}))
    end
  
    def perform_get(uri, options = {})
      handle_response(get(uri, {:query => options}))
    end
  
    def perform_post(uri, options = {})
      handle_response(post(uri, {:body => options}))
    end
  
    def perform_delete(uri, options = {})
      handle_response(delete(uri, {:body => options}))
    end
  
    def handle_response(response)
      unless response['error']
        return FGraph::Collection.new(response) if response['data']
        response
      else
        case response['error']['type']
          when 'QueryParseException'
            raise QueryParseError, response['error']
          when 'GraphMethodException'
            raise GraphMethodError, response['error']
          when 'OAuthException'
            raise OAuthError, response['error']
          when 'OAuthAccessTokenException'
            raise OAuthAccessTokenError, response['error']
          else
            raise FacebookError, response['error']
        end
      end
    end
  
    def format_url(path, options={})
      url = self.base_uri.dup
      url << path
      unless options.blank?
        url << "?"
      
        option_count = 0
      
        stringified_options = {}
        options.each do |key, value|
          stringified_options[key.to_s] = value
        end
        options = stringified_options
      
        options.each do |option|
          next if option[1].blank?
          url << "&" if option_count > 0
          url << "#{option[0]}=#{CGI.escape(option[1].to_s)}"
          option_count += 1
        end
      end
      url
    end
  
    def method_missing(name, *args, &block)
      names = name.to_s.split('_')
      super unless names.length > 1
    
      case names.shift
        when 'object'
          # object_photos
          self.object("#{args[0]}/#{names[0]}", args[1])
        when 'me'
          # me_photos
          self.me(names[0], args[0])
        when 'publish'
          # publish_feed(id)
          self.publish("#{args[0]}/#{names[0]}", args[1])
        when 'remove'
          # remove_feed(id)
          self.remove("#{args[0]}/#{names[0]}", args[1])
        when 'search'
          # search_user(query)
          options = args[1] || {}
          options[:type] = names[0]
          self.search(args[0], options)
        else
          super
      end
    end
  
    # Return ID['id'] if ID is a hash object
    #
    def get_id(id)
      return unless id
      id = id['id'] || id[:id] if id.is_a?(Hash)
      id
    end
  end
end