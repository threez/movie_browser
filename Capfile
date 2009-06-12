load 'deploy' if respond_to?(:namespace) # cap2 differentiator

set :application, "movie.ruby-consult.de" 
set :scm, :git
set :branch, 'master'
set :user, 'vlandgraf'
set :use_sudo, false
 
set :repository, "git@github.com:threez/movie_browser.git"
 
set :deploy_to, "/home/vlandgraf/movie-ruby-consult"
set :deploy_via, :remote_cache
 
set :domain, 'movie.ruby-consult.de'
role :app, domain
role :web, domain
 
set :runner, user
set :admin_runner, runner

namespace :deploy do
  task :restart do
    run "touch #{current_path}/tmp/restart.txt" 
  end
end
