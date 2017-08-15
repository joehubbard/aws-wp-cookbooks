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

  #Pagespeed Mod start
  execute "ps_dependencies" do
    command "sudo apt-get install build-essential zlib1g-dev libpcre3 libpcre3-dev unzip -y"
  end

  bash "ps_module" do
    cwd "/home/ubuntu"
    code <<-EOH
    mkdir tmp
    cd tmp
    git clone https://github.com/breeze2/ngx_pagespeed.so.git
    cd tmp
    sudo mkdir /etc/nginx/modules
    sudo cp ngx_pagespeed.so/ubuntu_x86_64/nginx-xenial-1.10.3/ngx_pagespeed.so /etc/nginx/modules/
    EOH
  end

  directory "/var/ngx_pagespeed_cache" do
    owner "www-data"
    group "www-data"
    mode "2775"
    action :create
    recursive true
  end

  mount '/var/ngx_pagespeed_cache' do
    pass     0
    fstype   'tmpfs'
    device   'tmpfs'
    options  'mode=775,size=500m'
    action   [:mount, :enable]
  end
  #Pagespeed Mod stop

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

  #execute "install-wp-cli" do
  #  command "curl -sS https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar && mv wp-cli.phar /usr/local/bin/wp"
  #end

  execute "install-composer" do
    command "curl -sS https://getcomposer.org/installer | php"
  end

  execute "install-composer-globally" do
    command "mv composer.phar /usr/local/bin/composer"
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
