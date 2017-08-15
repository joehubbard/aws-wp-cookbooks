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

  bash 'php_nginx_pagespeed' do
    cwd "/home/ubuntu"
    code <<-EOH
    apt-get update \
    && apt-get -y upgrade \
    && apt-get -y install autoconf automake bc bison build-essential ccache cmake curl dh-systemd flex gcc geoip-bin google-perftools g++ icu-devtools libacl1-dev libbz2-dev libcap-ng-dev libcap-ng-utils libcurl4-openssl-dev libdmalloc-dev libenchant-dev libevent-dev libexpat1-dev libfontconfig1-dev libfreetype6-dev libgd-dev libgeoip-dev libghc-iconv-dev libgmp-dev libgoogle-perftools-dev libice-dev libice6 libicu-dev libjbig-dev libjpeg-dev libjpeg-turbo8-dev libjpeg8-dev libluajit-5.1-2 libluajit-5.1-common libluajit-5.1-dev liblzma-dev libmhash-dev libmhash2 libmm-dev libncurses5-dev libnspr4-dev libpam0g-dev libpcre3 libpcre3-dev libperl-dev libpng-dev libpng12-dev libpthread-stubs0-dev libreadline-dev libselinux1-dev libsm-dev libsm6 libssl-dev libtidy-dev libtiff5-dev libtiffxx5 libunbound-dev libvpx-dev libvpx3 libwebp-dev libx11-dev libxau-dev libxcb1-dev libxdmcp-dev libxml2-dev libxpm-dev libxslt1-dev libxt-dev libxt6 make nano perl pkg-config software-properties-common systemtap-sdt-dev unzip webp wget xtrans-dev zip zlib1g-dev zlibc \
    && add-apt-repository -y ppa:ondrej/php \
    && apt-get update \
    && apt-get -y install php7.1-cli php7.1-dev php7.1-fpm php7.1-bcmath php7.1-bz2 php7.1-common php7.1-curl php7.1-gd php7.1-gmp php7.1-imap php7.1-intl php7.1-json php7.1-mbstring php7.1-mysql php7.1-readline php7.1-recode php7.1-soap php7.1-sqlite3 php7.1-xml php7.1-xmlrpc php7.1-zip php7.1-opcache php7.1-xsl php-yaml \
    && mkdir -p /usr/local/src/packages/{modules,nginx,openssl,pcre,zlib} \
    && mkdir -p /etc/nginx/{cache/{client,fastcgi,proxy,uwsgi,scgi},config/php,lock,logs,modules,pid,sites,ssl} \
    && useradd -d /etc/nginx nginx \
    && cd /usr/local/src/packages/nginx \
    && wget https://nginx.org/download/nginx-1.11.10.tar.gz \
    && tar xvf nginx-1.11.10.tar.gz --strip-components=1 \
    && cd /usr/local/src/packages/openssl \
    && wget https://www.openssl.org/source/openssl-1.1.0e.tar.gz \
    && tar xvf openssl-1.1.0e.tar.gz --strip-components=1 \
    && cd /usr/local/src/packages/pcre \
    && wget https://ftp.pcre.org/pub/pcre/pcre-8.40.tar.gz \
    && tar xvf pcre-8.40.tar.gz --strip-components=1 \
    && cd /usr/local/src/packages/zlib \
    && wget http://www.zlib.net/zlib-1.2.11.tar.gz \
    && tar xvf zlib-1.2.11.tar.gz --strip-components=1 \
    && cd /usr/local/src/packages/modules \
    && wget https://github.com/openresty/headers-more-nginx-module/archive/v0.32.tar.gz \
    && tar zxf v0.32.tar.gz \
    && wget https://github.com/simpl/ngx_devel_kit/archive/v0.3.0.tar.gz \
    && tar zxf v0.3.0.tar.gz \
    && wget https://github.com/FRiCKLE/ngx_cache_purge/archive/2.3.tar.gz \
    && tar zxf 2.3.tar.gz \
    && NPS_VERSION="1.12.34.2" \
    && cd /usr/local/src/packages/modules/ \
    && wget https://github.com/pagespeed/ngx_pagespeed/archive/v${NPS_VERSION}-beta.zip \
    && unzip v${NPS_VERSION}-beta.zip \
    && cd /usr/local/src/packages/modules/ngx_pagespeed-${NPS_VERSION}-beta \
    && psol_url=https://dl.google.com/dl/page-speed/psol/${NPS_VERSION}.tar.gz \
    && [ -e scripts/format_binary_url.sh ] && psol_url=$(scripts/format_binary_url.sh PSOL_BINARY_URL) \
    && wget ${psol_url} \
    && tar -xzvf $(basename ${psol_url}) \
    && cd /usr/local/src/packages/nginx \
    && ./configure --prefix=/etc/nginx \
                 --sbin-path=/usr/sbin/nginx \
                 --conf-path=/etc/nginx/config/nginx.conf \
                 --lock-path=/etc/nginx/lock/nginx.lock \
                 --pid-path=/etc/nginx/pid/nginx.pid \
                 --error-log-path=/etc/nginx/logs/error.log \
                 --http-log-path=/etc/nginx/logs/access.log \
                 --http-client-body-temp-path=/etc/nginx/cache/client \
                 --http-proxy-temp-path=/etc/nginx/cache/proxy \
                 --http-fastcgi-temp-path=/etc/nginx/cache/fastcgi \
                 --http-uwsgi-temp-path=/etc/nginx/cache/uwsgi \
                 --http-scgi-temp-path=/etc/nginx/cache/scgi \
                 --user=nginx \
                 --group=nginx \
                 --with-poll_module \
                 --with-threads \
                 --with-file-aio \
                 --with-http_ssl_module \
                 --with-http_v2_module \
                 --with-http_realip_module \
                 --with-http_addition_module \
                 --with-http_xslt_module \
                 --with-http_image_filter_module \
                 --with-http_sub_module \
                 --with-http_dav_module \
                 --with-http_flv_module \
                 --with-http_mp4_module \
                 --with-http_gunzip_module \
                 --with-http_gzip_static_module \
                 --with-http_auth_request_module \
                 --with-http_random_index_module \
                 --with-http_secure_link_module \
                 --with-http_degradation_module \
                 --with-http_slice_module \
                 --with-http_stub_status_module \
                 --with-stream \
                 --with-stream_ssl_module \
                 --with-stream_realip_module \
                 --with-stream_geoip_module \
                 --with-stream_ssl_preread_module \
                 --with-google_perftools_module \
                 --with-pcre=/usr/local/src/packages/pcre \
                 --with-pcre-jit \
                 --with-zlib=/usr/local/src/packages/zlib \
                 --with-openssl=/usr/local/src/packages/openssl \
                 --add-module=/usr/local/src/packages/modules/ngx_devel_kit-0.3.0 \
                 --add-module=/usr/local/src/packages/modules/headers-more-nginx-module-0.32 \
                 --add-module=/usr/local/src/packages/modules/ngx_cache_purge-2.3 \
                 --add-module=/usr/local/src/packages/modules/ngx_pagespeed-1.12.34.2-beta \
    && make \
    && make install
    EOH
  end

  # apt_package "php-fpm" do
  #   action :install
  # end
  #
  # apt_package "php-cli" do
  #   action :install
  # end
  #
  # apt_package "php-xml" do
  #   action :install
  # end
  #
  # apt_package "php-mbstring" do
  #   action :install
  # end
  #
  # apt_package "php7.0-gd" do
  #   action :install
  # end
  #
  # apt_package "php-mysql" do
  #   action :install
  # end

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

  bash "ps_dl_install" do
    cwd "/tmp"
    code <<-EOH
    NPS_VERSION=1.12.34.2-stable
    cd
    wget https://github.com/pagespeed/ngx_pagespeed/archive/v${NPS_VERSION}.zip
    unzip v${NPS_VERSION}.zip
    cd ngx_pagespeed-${NPS_VERSION}/
    NPS_RELEASE_NUMBER=${NPS_VERSION/beta/}
    NPS_RELEASE_NUMBER=${NPS_VERSION/stable/}
    psol_url=https://dl.google.com/dl/page-speed/psol/${NPS_RELEASE_NUMBER}.tar.gz
    [ -e scripts/format_binary_url.sh ] && psol_url=$(scripts/format_binary_url.sh PSOL_BINARY_URL)
    wget ${psol_url}
    tar -xzvf $(basename ${psol_url}) # extracts to psol/
    NGINX_VERSION=1.10.1
    cd
    wget http://nginx.org/download/nginx-${NGINX_VERSION}.tar.gz
    tar -xvzf nginx-${NGINX_VERSION}.tar.gz
    cd nginx-${NGINX_VERSION}/
    ./configure --add-module=$HOME/ngx_pagespeed-${NPS_VERSION} ${PS_NGX_EXTRA_FLAGS}
    make
    sudo make install
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
