set :rails_env, :production
set :stage, :production
set :application, "sharetribe"
set :nginx_server_name, "nection.com.au"
set :deploy_to, "/home/#{fetch(:user)}/www/#{fetch(:application)}"
# set :branch, "master"
set :unicorn_workers, 1
set :branch, "master"

# set :nginx_use_ssl, true
# set :nginx_ssl_certificate, "primcam.ru.crt"
# set :nginx_ssl_certificate_key, "primcam.ru.key"
# set :nginx_upload_local_certificate, -> { true }
# set :nginx_ssl_certificate_local_path, -> { "../certificates/#{fetch(:nginx_ssl_certificate)}" }
# set :nginx_ssl_certificate_key_local_path, -> { "../certificates/#{fetch(:nginx_ssl_certificate_key)}" }

