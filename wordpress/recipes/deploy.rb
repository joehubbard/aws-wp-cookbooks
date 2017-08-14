user = 'ubuntu'

search("aws_opsworks_app").each do |app|

  if app['deploy']
    db_switch = app['environment']['staging'] ||= nil ? 'staging' : 'wp'
    db = node['deploy']['wp']['database']
    app_name = app['domains'].pop()
    domains = app['domains'].join(" ")
    domains_cert = app['environment']['CERTBOT_DOMAINS'] ||= nil ? app['environment']['CERTBOT_DOMAINS'] : app['domains'].join(" -d ")
    wp_home =  app['environment']['WP_HOME']
    if app['environment']['MULTISITE']
      site_url = wp_home
    else
      site_url = "#{wp_home}/wp"
    end
    if app['environment']['WP_SITE_URL']
      site_url = app['environment']['WP_SITE_URL']
    end
    site_root = "/var/www/#{app['shortname']}/"
    shared_dir = "/efs/#{app['shortname']}/shared/"
    current_link = "#{site_root}current"
    time =  Time.new.strftime("%Y%m%d%H%M%S")
    release_dir = "#{site_root}releases/#{time}/"
    theme_dir = "#{release_dir}web/app/themes/#{app['environment']['THEME_NAME']}/"
    http_auth = false

    count_command = "ls -l #{site_root}releases/ | grep ^d | wc -l"
    directory_count = shell_out(count_command)

    if directory_count.stdout.to_i > 4
      execute "delete-oldest-release" do
        command "find #{site_root}releases/* -maxdepth 0 -type d -print | sort | head -n 1 | xargs rm -rf"
      end
    end

    directory "#{release_dir}" do
      owner "www-data"
      group "www-data"
      mode "2775"
      action :create
      recursive true
    end

    file "/home/#{user}/.ssh/id_rsa" do
      content "#{app['app_source']['ssh_key']}"
      owner "#{user}"
      group "opsworks"
      mode 00400
      action [:delete, :create]
    end

    execute "ssh-scan" do
      command "touch /home/#{user}/.ssh/known_hosts; ssh-keygen -f /home/#{user}/.ssh/known_hosts -R gitlab.com; ssh-keyscan -t rsa gitlab.com >> /home/#{user}/.ssh/known_hosts; ssh-keygen -f /home/#{user}/.ssh/known_hosts -R bitbucket.org; ssh-keyscan -t rsa bitbucket.org >> /home/#{user}/.ssh/known_hosts"
    end

    execute "ssh-git-clone" do
      command "ssh-agent sh -c 'ssh-add /home/#{user}/.ssh/id_rsa; git clone -b #{app['app_source']['revision']} --single-branch #{app['app_source']['url']} #{release_dir}'"
    end
    # NEED ADDING FOR MULTIPLE INSTANCES
    #directory "#{release_dir}web/app/uploads" do
    #  recursive true
    #  action :delete
    #end

    #link "#{release_dir}web/app/uploads" do
    #  to "#{shared_dir}web/app/uploads"
    #end

    template "#{release_dir}.env" do
      source "env.erb"
      mode "0644"
      group "www-data"
      owner "www-data"
      action [:delete, :create]

      variables(
        :db_name          =>  "#{db['database']}",
        :db_host          =>  "#{db['host']}",
        :db_user          =>  "#{db['username']}",
        :db_password      =>  "#{db['password']}",
        :wp_env           =>  "#{app['environment']['WP_ENV']}",
        :wp_home          =>  "#{wp_home}",
        :wp_siteurl       =>  "#{site_url}",
        :auth_key         =>  "#{app['environment']['AUTH_KEY']}",
        :secure_auth_key  =>  "#{app['environment']['SECURE_AUTH_KEY']}",
        :logged_in_key    =>  "#{app['environment']['LOGGED_IN_KEY']}",
        :nonce_key        =>  "#{app['environment']['NONCE_KEY']}",
        :auth_salt        =>  "#{app['environment']['AUTH_SALT']}",
        :secure_auth_salt =>  "#{app['environment']['SECURE_AUTH_SALT']}",
        :logged_in_salt   =>  "#{app['environment']['LOGGED_IN_SALT']}",
        :nonce_salt       =>  "#{app['environment']['NONCE_SALT']}",
        :acf_pro_key       =>  "#{app['environment']['ACF_PRO_KEY']}",
        :ilab_aws_s3_access_key       =>  "#{app['environment']['ILAB_AWS_S3_ACCESS_KEY']}",
        :ilab_aws_s3_access_secret       =>  "#{app['environment']['ILAB_AWS_S3_ACCESS_SECRET']}",
        :ilab_aws_s3_bucket       =>  "#{app['environment']['ILAB_AWS_S3_BUCKET']}",
        :ilab_aws_s3_cache_control => "#{app['environment']['ILAB_AWS_S3_CACHE_CONTROL']}",
        :ilab_media_imgix_enabled => "#{app['environment']['ILAB_MEDIA_IMGIX_ENABLED']}",
        :ilab_aws_s3_cdn_base => "#{app['environment']['ILAB_AWS_S3_CDN_BASE']}",
        :gmaps_api_key => "#{app['environment']['GMAPS_API_KEY']}"
      )
    end

    link "#{current_link}" do
      action :delete
    end

    link "#{current_link}" do
      to "#{release_dir}"
      notifies :run, "execute[reload-nginx-php]"
    end

    execute "reload-nginx-php" do
      command "nginx -t && service nginx reload && service php7.0-fpm restart"
      action :nothing
    end

    execute "run-composer" do
      command "composer install -d #{release_dir}"
    end

    execute "npm-install" do
      cwd "#{current_link}"
      command "npm install"
    end

    execute "webpack-install" do
      cwd "#{current_link}"
      command "npm run production"
      only_if { File.exists?("#{current_link}webpack.mix.js") }
    end

    execute "bower-install" do
      cwd "#{site_root}current/web"
      command "bower install --allow-root"
      only_if { File.exists?("#{theme_dir}bower.js") }
    end

    execute "gulp-production" do
      cwd "#{site_root}current/web"
      command "gulp --production"
      only_if { File.exists?("#{theme_dir}gulpfile.js") }
    end

    execute "change-directory-permissions" do
      command "find #{release_dir} -type d -exec chmod 2775 {} +"
    end

    execute "change-file-permissions" do
      command "find #{release_dir} -type f -exec chmod 0664 {} +"
    end

    execute "change-ownership" do
      command "chown -R www-data:www-data #{release_dir}"
    end
    
    if app['environment']['HTTP_AUTH_USER']
      http_auth = true
      template "/etc/nginx/htpasswd" do
        mode '0640'
        owner "www-data"
        group "www-data"
        source "htpasswd.erb"
        notifies :run, "execute[check-nginx]"
        variables(
          :http_auth_user => app['environment']['HTTP_AUTH_USER'],
          :http_auth_pass => app['environment']['HTTP_AUTH_PASS']
         )
      end
    end  
    
    enable_ssl = true
  
    if app['enable_ssl']
      Chef::Log.debug("enable_ssl is true, setup gui ssl certs")
      template "/etc/ssl/#{app['domains'].first}.crt" do
        mode '0640'
        owner "root"
        group "www-data"
        source "ssl.key.erb"
        variables :key => app['ssl_configuration']['certificate']
        only_if do
          app['enable_ssl']
        end
      end

      template "/etc/ssl/#{app['domains'].first}.key" do
        mode '0640'
        owner "root"
        group "www-data"
        source "ssl.key.erb"
        variables :key => app['ssl_configuration']['private_key']
        only_if do
          app['enable_ssl']
        end
      end

      template "/etc/ssl/#{app['domains'].first}.ca" do
        mode '0640'
        owner "root"
        group "www-data"
        source "ssl.key.erb"
        variables :key => app['ssl_configuration']['chain']
        only_if do
          app['enable_ssl']
        end
      end
      
      ssl_cert = "/etc/ssl/#{app['domains'].first}.crt"
      ssl_key = "/etc/ssl/#{app['domains'].first}.key"
      ssl_ca = "/etc/ssl/#{app['domains'].first}.ca"

    end
    
    if app['environment']['CERTBOT']
        Chef::Log.debug("certbot is true, setup certbot")
        if Dir.exist?("/etc/letsencrypt/live/#{app['domains'].first}")
          Chef::Log.debug("letsencrypt folder exists")
        else
          execute "certbot" do
            command "certbot certonly --webroot -w #{current_link}web -d #{domains_cert} --agree-tos --email james.hall@impression.co.uk --non-interactive"
          end

          template "/etc/cron.daily/certbot" do
            source "daily-cron.erb"
            owner "root"
            group "root"
            mode "644"
          end
        
        end
      
      ssl_cert = "/etc/letsencrypt/live/#{app['domains'].first}/fullchain.pem"
      ssl_key = "/etc/letsencrypt/live/#{app['domains'].first}/privkey.pem"
      ssl_ca = "/etc/letsencrypt/live/#{app['domains'].first}/fullchain.pem"

    end
    
    template "/etc/nginx/sites-available/nginx-#{app['shortname']}.conf" do
      source "nginx-wordpress.conf.erb"
      owner "root"
      group "www-data"
      mode "640"
      notifies :run, "execute[check-nginx]"
      variables(
        :web_root => "#{site_root}current/web",
        :domains => domains,
        :app_name => app['shortname'],
        :enable_ssl => enable_ssl,
        :ssl_cert => ssl_cert,
        :ssl_key => ssl_key,
        :ssl_ca => ssl_ca,
        :multisite => app['environment']['MULTISITE'],
        :http_auth => http_auth
      )
    end

    link "/etc/nginx/sites-enabled/nginx-#{app['shortname']}.conf" do
      to "/etc/nginx/sites-available/nginx-#{app['shortname']}.conf"
    end

    execute "check-nginx" do
      command "nginx -t"
      action :nothing
    end
    
    directory "/home/root" do
      owner "root"
      group "root"
      mode 755
      recursive true
    end
    
    directory "/root/.aws" do
      owner "root"
      group "root"
      mode 755
      recursive true
    end

    template "/root/.aws/credentials" do
      source "aws-credentials.erb"
      owner "root"
      group "www-data"
      mode "640"
      variables(
        :aws_access_key => app['environment']['AWS_ACCESS_KEY'],
        :aws_access_secret_key => app['environment']['AWS_ACCESS_SECRET_KEY']
      )
      only_if do
        app['environment']['AWS_ACCESS_KEY'] && app['environment']['AWS_ACCESS_SECRET_KEY']
      end
    end

    template "/etc/logrotate.d/nginx" do
      source "logrotate-nginx.erb"
      owner "root"
      group "www-data"
      mode "0644"
      action [:delete, :create]
    end

  end

end
