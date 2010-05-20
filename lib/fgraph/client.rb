require 'oauth2'

module FGraph
  
  # Facebook proxy class to call Facebook Graph API methods with default options.
  # Please refer to FGraph method documentation for more information.
  class Client
    attr_reader :oauth_client, :client_id, :client_secret, :options

    # Initialize Client with default options, so options are not required to be passed
    # when calling respective Facebook Graph API methods.
    # 
    # ==== Options
    # * <tt>client_id</tt> - Application API key
    # * <tt>client_secret</tt> - Application Secret
    # * <tt>app_id</tt> - Application ID
    # * <tt>access_token</tt> - Access token, required to publish to Facebook Graph or access
    #   current user profile.
    # * <tt>app_access_token</tt> - Application access token, required to access Facebook insights.
    #   Auto generated if client_id and client_secret option are provided.
    #
    #   # Initialize with default options
    #   fg_client = FGraph::Client.new(:client_id => '...', :client_secret => '...')
    #   fg_client.oauth_authorize_url(:redirect_uri => 'http://www.example.com/oauth_redirect')
    #   fg_client.oauth_access_token(:redirect_uri => '...', :code => '...')
    #   
    #   # Intialize with access token
    #   fg_client = FGraph::Client.new(:access_token => '...')
    #   fg_client.me
    #   fg.client.publish_feed('herryanto', :message => 'Cool!')
    #
    def initialize(options={})
      @options = options
    end
    
    def oauth_authorize_url(redirect_uri)
      FGraph.oauth_authorize_url(self.options[:client_id], redirect_uri)
    end
    
    def oauth_access_token(redirect_uri, code)
      FGraph.oauth_access_token(self.options[:client_id], self.options[:client_secret],
        :redirect_uri => redirect_uri, :code => code)
    end
    
    def oauth_app_access_token
      FGraph.oauth_app_access_token(self.options[:client_id], self.options[:client_secret])
    end
    
    def object(id, options={})
      FGraph.object(id, {:access_token => self.options[:access_token]}.merge(options || {}))
    end
    
    def objects(*args)
      return if args.blank?
      options = args.last.is_a?(Hash) ? args.pop : {}
      options[:access_token] = self.options[:access_token]
      args << options
      
      FGraph.objects(args)
    end
    
    def me(*args)
      return if args.blank?
      options = args.last.is_a?(Hash) ? args.pop : {}
      options[:access_token] = self.options[:access_token]
      args << options
      
      FGraph.me(args)
    end
    
    def publish(id, options={})
      FGraph.publish(id, {
        :access_token => self.options[:access_token]
      }.merge(options || {}))
    end
    
    def remove(id, options={})
      FGraph.remove(id, {
        :access_token => self.options[:access_token]
      }.merge(options || {}))
      
    end
    
    def search(query, options={})
      FGraph.search(query, options)
    end
    
    def insights(options={})
      unless self.options[:app_access_token]
        self.options[:app_access_token] = self.oauth_app_access_token
      end
      FGraph.insights(self.options[:app_id], self.options[:app_access_token], options)
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
  end
end 