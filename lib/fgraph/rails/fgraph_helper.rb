module FGraph
  module Rails
    module FGraphHelper
      
      # Access FGraph.config initialized with values set in <tt>[RAILS_ROOT]/config/fgraph.yml</tt>.
      def fgraph_config
        FGraph.config || {}
      end

      # Return Facebook session, default to retrieve session from cookies.
      def fgraph_session(app_id = fgraph_config['app_id'], 
        app_secret = fgraph_config['app_secret'])
        
        return @fgraph_session if @fgraph_session
        @fgraph_session = fgraph_session_cookies(app_id, app_secret)
      end
    
      # Return Facebook session cookies.
      def fgraph_session_cookies(app_id = fgraph_config['app_id'], 
        app_secret = fgraph_config['app_secret'])

        return @fgraph_session_cookies if @fgraph_session_cookies
        return if @fgraph_session_cookies == false

        fbsr_cookie = request.cookies["fbsr_#{app_id}"]
        if app_id.blank? or app_secret.blank? or fbsr_cookie.blank?
          return @fgraph_session_cookies = false
        end

        # Get authorization code and access token
        signed_request = fgraph_parse_signed_request(fbsr_cookie, app_secret)
        resp = FGraph.oauth_access_token(app_id, app_secret, :code => signed_request['code'])

        @fgraph_session_cookies = { 
          'access_token' => resp['access_token'] 
        }
      end

      def fgraph_base64_url_decode(str)
        str += '=' * (4 - str.length.modulo(4))
        Base64.decode64(str.tr('-_', '+/'))
      end

      # Parses a signed request string provided by Facebook to canvas apps or in a secure cookie.
      #
      # @param  Input the signed request from Facebook
      # @raise  RuntimeError if the signature is incomplete, invalid, or using an unsupported algorithm
      # @return A hash of the validated request information
      def fgraph_parse_signed_request(input, app_secret)
        encoded_sig, encoded_envelope = input.split('.', 2)
        raise FGraph::OAuthError, 'SignedRequest: Invalid (incomplete) signature data' unless encoded_sig && encoded_envelope

        signature = fgraph_base64_url_decode(encoded_sig).unpack("H*").first
        envelope = ActiveSupport::JSON.decode(fgraph_base64_url_decode(encoded_envelope))
        raise FGraph::OAuthError, "SignedRequest: Unsupported algorithm #{envelope['algorithm']}" if envelope['algorithm'] != 'HMAC-SHA256'

        hmac = OpenSSL::HMAC.hexdigest(OpenSSL::Digest::SHA256.new, app_secret, encoded_envelope)
        raise FGraph::OAuthError, 'SignedRequest: Invalid signature' if (signature != hmac)

        envelope
      end
      
      def fgraph_access_token
        return unless fgraph_session
        fgraph_session['access_token']
      end
      
      def fgraph_logged_in?
        return true if fgraph_session and fgraph_access_token
      end
    
      # Currently logged in facebook user
      def fgraph_current_user
        return @fgraph_current_user if @fgraph_current_user
        @fgraph_current_user = fgraph_client.me 
      end
      
      # Alias for fgraph_current_user
      def fgraph_user
        fgraph_current_user
      end
      
      # Return FGraph::Client instance initialized with settings set in <tt>fgraph.yml</tt>.
      # Initialized with <tt>:access_token</tt> as well if Facebook session exists.
      def fgraph_client
        return @fgraph_client if @fgraph_client
        
        @fgraph_client = FGraph::Client.new(
         :client_id => fgraph_config['app_id'],
         :client_secret => fgraph_config['app_secret'],
         :access_token => fgraph_access_token
        )
      end
      
      # Return Facebook object picture url: http://graph.facebook.com/[id]/picture
      #
      # ==== Type Options
      # * <tt>square</tt> - 50x50 (default)
      # * <tt>small</tt> - 50 pixels wide, variable height
      # * <tt>normal</tt> - 100 pixels wide, variable height
      # * <tt>large</tt> - 200 pixels wide, variable height
      #
      def fgraph_picture_url(id, type=nil)
        id = FGraph.get_id(id)
        url = "http://graph.facebook.com/#{id}/picture"
        url += "?type=#{type}" if type
        url
      end
    end
  end
end