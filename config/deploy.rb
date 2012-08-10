set :application, "jslabot"
set :application_port, 5002

set :scm, :git
set :scm_verbose, true

set :repository, "git://github.com/jsla/#{application}.git"
set :branch, "master"

set :user, "deploy"                               # user to ssh in as
set :use_sudo, false
set :ssh_options, { :forward_agent => true }

set :deploy_to, "/home/#{user}/#{application}" 
set :deploy_via, :remote_cache
set :keep_releases, 5

set :admin_runner, 'deploy'                       # user to run the application node_file as
set :application_binary, 'bin/start'  # application for running your app. Use coffee for coffeescript apps

set :node_env, 'production'

set :log_path, "/home/#{user}/logs/#{application}.log"

default_run_options[:pty] = true


# Production deploy task
task :production do
  set :branch, "master"
  set :top_level_task, "production"

  set :app_host, "jslabot.js.la"

  role :app, "66.172.10.130"
  role :web, "66.172.10.130"
  role :db,  "66.172.10.130", :primary => true
end

namespace :deploy do
  task :start, :roles => :app, :except => { :no_release => true } do
    run "sudo start #{application}"
  end

  task :stop, :roles => :app, :except => { :no_release => true } do
    run "sudo stop #{application}"
  end

  task :restart, :roles => :app, :except => { :no_release => true } do
    run "sudo restart #{application} || sudo start #{application}"
  end

  desc "Check required packages and install if packages are not installed"
  task :update_packages, roles => :app do
    run "cd #{release_path} && npm install"
    # run "cd #{release_path} && npm rebuild"
  end

  task :create_deploy_to, :roles => :app do
    run "mkdir -p #{deploy_to}"
  end
  
  desc "writes the upstart script for running the daemon. Customize to your needs"
  task :write_upstart_script, :roles => :app do
    upstart_script = <<-UPSTART
  description "#{application}"

  start on runlevel [2345]
  stop on shutdown

  script
      # We found $HOME is needed. Without it, we ran into problems
      export HOME="/home/#{admin_runner}"
      export NODE_ENV="#{node_env}"
      cd #{current_path}

      exec sudo -u #{admin_runner} sh -c "NODE_ENV=#{node_env} PORT=#{application_port} #{application_binary} >> #{log_path} 2>&1"
  end script
  respawn
UPSTART
  put upstart_script, "/tmp/#{application}_upstart.conf"
    run "sudo mv /tmp/#{application}_upstart.conf /etc/init/#{application}.conf"
  end

  desc "Update submodules"
  task :update_submodules, :roles => :app do
    run "cd #{release_path}; git submodule init && git submodule update"
  end

  desc "create deployment directory"
  task :create_deploy_to, :roles => :app do
    run "mkdir -p #{deploy_to}"
  end

end


before 'deploy:setup', 'deploy:create_deploy_to'
after 'deploy:setup', 'deploy:write_upstart_script'

after "deploy:finalize_update", "deploy:update_submodules", "deploy:update_packages"