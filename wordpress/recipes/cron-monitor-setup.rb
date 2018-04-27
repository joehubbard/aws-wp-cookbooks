user = 'ubuntu'

search("aws_opsworks_app").each do |app|

  if app['deploy']
    
    enable_ssl = true
    http_auth = false
    app_name = app['domains'].pop()
    domains = app['domains'].join(" ")
    domains_cert = app['environment']['CERTBOT_DOMAINS'] ||= nil ? app['environment']['CERTBOT_DOMAINS'] : app['domains'].join(" -d ")
    site_root = "/var/www/#{app['shortname']}/"
    shared_dir = "/efs/#{app['shortname']}/shared/"
    current_link = "#{site_root}current/"
    wp_home =  app['environment']['WP_HOME']
  
    template "/etc/cron.hourly/wpcron" do
            source "hourly-cron.erb"
            owner "root"
            group "root"
            mode "644"
            variables(
                :wp_home => "#{wp_home}"
            )
            only_if do
                !File.file?("/etc/cron.hourly/wpcron")
            end
    end

    execute "download-amplify" do
       command "curl -L -O https://github.com/nginxinc/nginx-amplify-agent/raw/master/packages/install.sh"
    end

    execute "install-amplify" do
       command "API_KEY='35941d27b405b44ff8ce6a051784cf2f' sh ./install.sh"
    end

    template "/etc/nginx/conf.d/stub_status.conf" do
          source "stub_status.conf.erb"
          owner "root"
          group "www-data"
          mode "640"
          notifies :run, "execute[restart-nginx]"
    end

    template "/etc/nginx/conf.d/log_variables.conf" do
              source "log_variables.conf.erb"
              owner "root"
              group "www-data"
              mode "640"
              notifies :run, "execute[restart-nginx]"
     end

    template "/etc/php/7.0/fpm/pool.d/www.conf" do
            source "www.conf.erb"
            owner "root"
            group "root"
            mode "644"
            notifies :run, "execute[restart-php]"
    end

    execute "reload-nginx-php" do
      command "nginx -t && service nginx reload && service php7.0-fpm restart"
      action :nothing
    end
  
  end
end
