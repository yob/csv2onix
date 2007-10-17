gemtracker_base = File.expand_path(File.dirname(__FILE__) + '/../../gemtracker/lib')
$LOAD_PATH.unshift(gemtracker_base) if File.exist?(gemtracker_base)

require 'gem_list'
require 'rubygems'

namespace :gems do
  
  desc 'Install all gems listed in config/gems.yml'
  task :install do
    GemList.instance.each_pair do |g,v|
      begin
        gem (g, v)
      rescue Gem::LoadError
        system('gem', 'install', '--version', v, g)
      end
    end
  end

end
