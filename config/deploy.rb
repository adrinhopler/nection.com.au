require 'yaml'

set :user, "ubuntu"
server "54.200.159.64", user: fetch(:user), roles: %w{web app db}
set :repo_url,  "git@bitbucket.org:obavaev/nection.com.au.git"

set :rvm_ruby_version, '2.3.1'
set :nginx_port, 80
set :keep_releases, 2

set :linked_dirs, fetch(:linked_dirs, []) + %w(log tmp/pids public/system)
set :linked_files, fetch(:linked_files, []) + %w{config/database.yml}
set :config_files, %w(config/database.yml)
before 'deploy:check:linked_files', 'config:push'
before 'deploy:check:linked_files', 'linked_files:touch'

set :pty, true
set :ssh_options, {
  forward_agent: true,
  auth_methods: ["publickey"],
  keys: ["../download/sharetribe-new-64.pem"]
}

# nvm
set :nvm_node, 'v6.1.0'

set :default_env, {
  'PATH' => '/home/ubuntu/.nvm/versions/node/v6.1.0/bin:$PATH'
}

namespace :deploy do
  desc "tail logs"
  task :tail_logs do
    on roles(:app) do
      execute "tail -f #{shared_path}/log/#{fetch(:rails_env)}.log"
    end
  end
end

namespace :rails do
  desc 'Open a rails console `cap [staging] rails:console [server_index default: 0]`'
  task :console do
    on roles(:app) do |server|
      server_index = ARGV[2].to_i
      return if server != roles(:app)[server_index]

      puts "Opening a console on: #{host}...."
      cmd = "ssh #{server.user}@#{host} -t 'cd #{fetch(:deploy_to)}/current && ~/.rvm/bin/rvm #{fetch(:rvm_ruby_version)} do bundle exec rails console #{fetch(:rails_env)}'"
      puts cmd
      exec cmd
    end
  end
end

namespace :log do
  desc "Tail all application log files"
  task :tail do
    on roles(:app) do |server|
      execute "tail -f #{current_path}/log/*.log" do |channel, stream, data|
        puts "#{channel[:host]}: #{data}"
        break if stream == :err
      end
    end
  end
end

desc "Run rake task on server"
task :sake do
 on roles(:app), in: :sequence, wait: 5 do
   within current_path do
     as :rails do
       with rails_env: :production do
         execute :rake, ENV['task'], "RAILS_ENV=production"
       end
     end
   end
 end
end


namespace :deploy do

  desc "Create database and database user"
  task :create_mysql_database do
    db_configuration = YAML::load(IO.read("config/database.#{fetch(:stage)}.yml"))[fetch(:rails_env).to_s]
    ask :db_root_password, ''

    on roles(:app) do
      execute "mysql --user=root --password=#{fetch(:db_root_password)} -e \"CREATE DATABASE IF NOT EXISTS #{db_configuration['database']} CHARACTER SET #{db_configuration['encoding']}\""
      execute "mysql --user=root --password=#{fetch(:db_root_password)} -e \"GRANT ALL PRIVILEGES ON #{db_configuration['database']}.* TO '#{db_configuration['username']}'@'localhost' IDENTIFIED BY '#{db_configuration['password']}' WITH GRANT OPTION\""
    end
  end

  task :drop_mysql_database do
    db_configuration = YAML::load(IO.read("config/database.#{fetch(:stage)}.yml"))[fetch(:rails_env).to_s]
    ask :db_root_password, ''

    on roles(:app) do
      execute "mysql --user=root --password=#{fetch(:db_root_password)} -e \"DROP DATABASE IF EXISTS #{db_configuration['database']}\""
    end
  end
end

namespace :deploy do
  task :fix_absent_manifest_bug do
    on roles(:web) do
      within release_path do  execute :touch,
        release_path.join('public', fetch(:assets_prefix), 'manifest-fix.temp')
      end
   end
  end

  after 'deploy:assets:precompile', 'deploy:fix_absent_manifest_bug'
end

Rake::Task["deploy:start"].clear_actions
Rake::Task["deploy:restart"].clear_actions
Rake::Task["deploy:stop"].clear_actions
namespace :deploy do
  %w[start stop restart].each do |command|
    desc "#{command} unicorn"
    task command do
      on roles(:app) do
        execute "sudo service unicorn_#{fetch(:application)} #{command}"
      end
    end
  end
  after :publishing, "deploy:restart"
end
