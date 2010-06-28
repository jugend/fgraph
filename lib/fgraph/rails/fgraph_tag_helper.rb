module FGraph
  module Rails
    module FGraphTagHelper
      def fgraph_javascript_include_tag
        %{<script src="http://connect.facebook.net/en_US/all.js"></script>}
      end
      
      # Inititalize XFBML Javascript include and initialization script.
      #
      # ==== Options
      # * <tt>app_id</tt> - overrride Fgraph.config['app_id'] value.
      # * <tt>async</tt> - asynchronous javascript include & initialization.
      #   for other Facebook JS initialization codes please wrap under:
      #
      #   window.afterFbAsyncInit = function() {
      #       ....
      #   }
      #
      def fgraph_javascript_init_tag(options={})
        options = { :app_id => FGraph.config['app_id'] }.merge(options || {})
        
        if options[:async]
          %{
            <div id="fb-root"></div>
            <script>
              window.fbAsyncInit = function() {
                FB.init({appId: '#{options[:app_id]}', status: true, cookie: true,
                         xfbml: true});
                         
                if (window.afterFbAsyncInit) {
                  window.afterFbAsyncInit();
                }
              };
              (function() {
                var e = document.createElement('script'); e.async = true;
                e.src = document.location.protocol +
                  '//connect.facebook.net/en_US/all.js';
                document.getElementById('fb-root').appendChild(e);
              }());
            </script>
          }
        else
          tag = fgraph_javascript_include_tag
          tag << %{
            <div id="fb-root"></div>
            <script>
              FB.init({appId: '#{options[:app_id]}', status: true, cookie: true, xfbml: true});
            </script>
          }
        end
      end

      def fgraph_image_tag(id, type=nil, options={})
        default_options = fgraph_image_options(type)
        default_options[:alt] = id['name'] if id.is_a?(Hash)
        image_tag(fgraph_picture_url(id, type), default_options.merge(options || {}))
      end
      
      def fgraph_image_options(type)
        case type
          when 'square'
            {:width => 50, :height => 50}
          when 'small'
            {:width => 50}
          when 'normal'
            {:width => 100}
          when 'large'
            {:width => 200}
          else
            {:width => 50, :height => 50}
        end
      end
    end 
  end
end