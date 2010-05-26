module FGraph
  module Rails
	  module FGraphHelper
	    
	    # Access FGraph.config initialized with values set in <tt>[RAILS_ROOT]/config/fgraph.yml</tt>.
	    def fgraph_config
  		  FGraph.config || {}
  		end

		  # Return Facebook session, default to retrieve session from cookies
  		def fgraph_session(app_id = fgraph_config['app_id'], 
  		  app_secret = fgraph_config['app_secret'])
  			
  			return @fgraph_session if @fgraph_session
  			@fgraph_session = fgraph_session_cookies(app_id, app_secret)
  		end
		
		  # Return Facebook_session cookies
  		def fgraph_session_cookies(app_id = fgraph_config['app_id'], 
  			app_secret = fgraph_config['app_secret'])
			
  			return @fgraph_session_cookies if @fgraph_session_cookies
  			return if @fgraph_session_cookies == false
			
  			 # retrieve session from cookies
  			fbs_cookies = request.cookies["fbs_#{app_id}"]
  			if app_id.blank? or app_secret.blank? or fbs_cookies.blank?
  				return @fgraph_session_cookies = false
  			end

  			# Parse facebook cookies
  			fbs_cookies = CGI.parse(fbs_cookies.gsub!(/(^\"|\"$)/, ''))
  			session_cookies = {}
  			fbs_cookies.each do |key, value|
  				session_cookies[key] = value[0]
  			end
  			
  			# Validate session cookies
  			cookie_message = ''
  			session_cookies_list = session_cookies.sort
  			session_cookies_list.each do |cookie|
  				cookie_message += "#{cookie[0]}=#{cookie[1]}" if cookie[0] != 'sig'
  			end

  			# Message digest does not match
  			if Digest::MD5.hexdigest(cookie_message + app_secret) != session_cookies['sig']
  				@fgraph_session_cookies = false
  			end

  			@fgraph_session_cookies = session_cookies
  		end
		
  		def fgraph_access_token
  			return unless fgraph_session
  			fgraph_session['access_token']
  		end
  		
  		def fgraph_logged_in?
  		  return true if fgraph_session and fgraph_access_token
  		end
		
  		def fgraph_current_user
  		  return @fgraph_current_user if @fgraph_current_user
  		  @fgraph_current_user = fgraph_client.me 
  		end
  		
  		# Return FGraph::Client.instance initialized with settings set in <tt>fgraph.yml</tt>.
  		# Initialized with <tt>:access_token</tt> as well if Facebook session exists.
  		def fgraph_client
  		  return @fgraph_client if @fgraph_client
  		  
  		  @fgraph_client = FGraph::Client.new(
  			 :client_id => fgraph_config['app_id'],
  			 :client_secret => fgraph_config['app_secret'],
  			 :access_token => fgraph_access_token
  		  )
  		end
    end
  end
end