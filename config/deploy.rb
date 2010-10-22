# Capistrano Deploy Recipes

require "bundler/capistrano"

default_run_options[:pty] = true

set :application, "csv2onix"
set :repository,  "ssh://jh@dib.deefa.com/srv/git/yob/csv2onix.git"
set :domain, "dib.deefa.com"
set :user, "jh"
set :branch, "master"
set :init_script, "rails"

# If you aren't deploying to /u/apps/#{application} on the target
# servers (which is the default), you can specify the actual location
# via the :deploy_to variable:
set :deploy_to, "/srv/rails/#{application}"

# If you aren't using Subversion to manage your source code, specify
# your SCM below:
set :scm, :git
set :deploy_via, :remote_cache

role :app, domain
role :web, domain
role :db,  domain, :primary => true

# setup symlinks to the sphinx index dir and artifacts
task :create_symlinks, :roles => [:app] do
  run "ln -s #{shared_path}/cache #{release_path}/tmp/cache"
  run "ln -s #{shared_path}/sockets #{release_path}/tmp/sockets"
  run "ln -s #{shared_path}/sessions #{release_path}/tmp/sessions"
  run "ln -s #{shared_path}/files #{release_path}/tmp/files"
end
after 'deploy:update_code', :create_symlinks

# check file permissions are correct
task :check_permissions, :roles => [:app] do
  run "chown -R jh:www-data #{release_path}"
  run "chmod -R ug+rwx #{release_path}"
end
after 'create_symlinks', :check_permissions

# clean up old releases
after 'deploy', 'deploy:cleanup'

# custom rules for starting and stopping thin processes
# We use the debian init.d system, not direct thin calls
namespace :deploy do
  desc "custom restart task for thin cluster"
  task :restart, :roles => :app, :except => {:no_release => true} do
    sudo "invoke-rc.d #{init_script} restart"
  end

  desc "custom start task for thin cluster"
  task :start, :roles => :app do
    sudo "invoke-rc.d #{init_script} start"
  end

  desc "custom stop task for thin cluster"
  task :stop, :roles => :app do
    sudo "invoke-rc.d #{init_script} stop"
  end
end

# customer maintenance page tasks
namespace :deploy do
  namespace :web do

    desc "custom task that raises a maintenance page"
    task :disable, :roles => :app do
      run "mv #{shared_path}/system/maintenance.bak.html #{shared_path}/system/maintenance.html"
    end

    desc "custom task that raises a maintenance page"
    task :enable, :roles => :app do
      run "mv #{shared_path}/system/maintenance.html #{shared_path}/system/maintenance.bak.html"
    end
  end
end
