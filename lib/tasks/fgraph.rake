require 'fileutils'

namespace :fgraph do
  desc "Create fgraph.yml configuration file in Rails config folder"
  task :setup => :environment do
    fgraph_config = File.join(Rails.root, "config", "fgraph.yml")
    fgraph_template_dir = File.join(Rails.root, "vendor", "plugins", "fgraph", "templates")
    
    unless File.exists?(fgraph_template_dir)
      fgraph_data_dir = Gem.datadir('fgraph')
      if fgraph_data_dir
        fgraph_template_dir = fgraph_data_dir.split('/')[0..-3].join('/') + '/templates'
      end
    end
    
    unless File.exist?(fgraph_config)
      fgraph_config_template = File.join(fgraph_template_dir, "fgraph.yml")
      FileUtils.cp fgraph_config_template, fgraph_config
      puts "#{RAILS_ROOT}/config/fgraph.yml created, please update your app_id and app_secret."
    else
      puts "#{RAILS_ROOT}/config/fgraph.yml already exists."
    end
  end
end