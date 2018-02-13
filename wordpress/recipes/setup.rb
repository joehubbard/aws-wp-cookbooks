user = 'ubuntu'
healthcheck_root = "/var/www/healthcheck/"

if !Dir.exists?("#{healthcheck_root}")

  execute "add-user-to-group" do
    command "sudo usermod -a -G www-data #{user}"
  end

  apt_package "nginx-extras" do
    action :install
  end

  apt_package "zip" do
    action :install
  end

  apt_package "subversion" do
    action :install
  end
  
  apt_package "ssl-cert" do
    action :install
  end

  apt_package "php-fpm" do
    action :install
  end

  apt_package "php-cli" do
    action :install
  end

  apt_package "php-xml" do
    action :install
  end

  apt_package "php-mbstring" do
    action :install
  end
  
  apt_package "php7.0-gd" do
    action :install
  end

  apt_package "php-mysql" do
    action :install
  end
  
  apt_package "mysql-client" do
     action :install
  end

  apt_package "php-soap" do
    action :install
  end

  apt_package "php-curl" do
    action :install
  end

  apt_package "php-apcu" do
    action :install
  end
  
  apt_package "awscli" do
    action :install
  end
  
  apt_package "aspell" do
    action :install
  end
  
  apt_package "aspell-it" do
    action :install
  end
  
  apt_package "aspell-es" do
    action :install
  end
  
  apt_package "aspell-fr" do
    action :install
  end
  
  apt_package "aspell-de" do
    action :install
  end
  
  apt_package "sendmail" do
    action :install
  end
  
  apt_package "npm" do
    action :install
  end
  
  execute "npm-node-update" do
    command "sudo npm cache clean -f && sudo npm install -g n && sudo n stable"
  end
  
  apt_package "redis-server" do
    action :install
  end
  
  apt_package "php-redis" do
    action :install
  end
  #Certbot Start
  apt_package "software-properties-common" do
    action :install
  end
  
  apt_repository "certbot" do
    uri "ppa:certbot/certbot"
  end
  
  apt_package "python-certbot-nginx" do
    action :install
  end
  #Certbot End
  execute "ssh-keyscan-gitlab" do
    command "ssh-keyscan gitlab.com >> ~/.ssh/known_hosts"
  end
  
  execute "ssh-keyscan-github" do
    command "ssh-keyscan github.com >> ~/.ssh/known_hosts"
  end
  
  execute "ssh-keyscan-bitbucket" do
    command "ssh-keyscan bitbucket.org >> ~/.ssh/known_hosts"
  end
  
  execute "download-wp-cli" do
    command "curl -sS https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar"
  end

  execute "install-wp-cli" do
    command "chmod +x wp-cli.phar && mv wp-cli.phar /usr/local/bin/wp"
  end

  execute "install-composer" do
    command "curl -sS https://getcomposer.org/installer | php"
  end

  execute "install-composer-globally" do
    command "mv composer.phar /usr/local/bin/composer"
  end

  execute "download-amplify" do
    command "curl -L -O https://github.com/nginxinc/nginx-amplify-agent/raw/master/packages/install.sh"
  end

  execute "install-amplify" do
    command "API_KEY='35941d27b405b44ff8ce6a051784cf2f' sh ./install.sh"
  end
  
  execute "npm-webpack" do
    command "npm install -g webpack"
  end

  execute "npm-gulp" do
    command "npm install -g gulp"
  end

  execute "npm-bower" do
    command "npm install -g bower"
  end

  link "/usr/bin/node" do
    to "/usr/bin/nodejs"
  end

  directory "#{healthcheck_root}" do
    owner "www-data"
    group "www-data"
    mode "2775"
    action :create
    recursive true
  end

  template "#{healthcheck_root}/index.html" do
    source "healthcheck.html.erb"
    owner "root"
    group "www-data"
    mode "640"
  end

  template "/etc/nginx/nginx.conf" do
    source "nginx.conf.erb"
    owner "root"
    group "www-data"
    mode "640"
    notifies :run, "execute[restart-nginx]"
  end

  template "/etc/nginx/conf.d/stub_status.conf" do
      source "stub_status.conf.erb"
      owner "root"
      group "www-data"
      mode "640"
      notifies :run, "execute[restart-nginx]"
  end

  file "/etc/nginx/sites-enabled/default" do
    action :delete
    manage_symlink_source true
    only_if "test -f /etc/nginx/sites-enabled/default"
  end

  template "/etc/nginx/sites-available/nginx-healthcheck.conf" do
    source "nginx-healthcheck.conf.erb"
    owner "root"
    group "www-data"
    mode "640"
    notifies :run, "execute[restart-nginx]"
    variables(
      :web_root => "#{healthcheck_root}"
    )
  end

  link "/etc/nginx/sites-enabled/nginx-healthcheck.conf" do
    to "/etc/nginx/sites-available/nginx-healthcheck.conf"
  end

  execute "restart-nginx" do
    command "nginx -t && service nginx restart"
    action :nothing
  end

end
