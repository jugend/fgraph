require 'rubygems'
require 'fileutil'

fgraph_config = File.join(RAILS_ROOT, "config", "fgraph.yml")
unless File.exist?(fgraph_config)
  fgraph_config_template = File.join(RAILS_ROOT, "vendor", "plugins", "fgraph", "templates", "fgraph.yml")
  FileUtils.cp fgraph_config_template, fgraph_config
  puts "#{RAILS_ROOT}/config/fgraph.yml created, please update your app_id and app_secret."
end