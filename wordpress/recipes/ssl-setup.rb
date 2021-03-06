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
      
          execute "certbot" do
            command "certbot certonly --webroot -w #{current_link}web -d #{domains_cert} --agree-tos --email james.hall@impression.co.uk --non-interactive --expand"
          end

          ssl_cert = "/etc/letsencrypt/live/#{app['domains'].first}/fullchain.pem"
          ssl_key = "/etc/letsencrypt/live/#{app['domains'].first}/privkey.pem"
          ssl_ca = "/etc/letsencrypt/live/#{app['domains'].first}/fullchain.pem"

          template "/etc/cron.daily/certbot" do
            source "daily-cron.erb"
            owner "root"
            group "root"
            mode "644"
          end

    end
    
    template "/etc/nginx/sites-available/nginx-#{app['shortname']}.conf" do
      source "nginx-wordpress.conf.erb"
      owner "root"
      group "www-data"
      mode "640"
      notifies :run, "execute[reload-nginx-php]"
      variables(
        :web_root => "#{site_root}current/web",
        :domains => domains,
        :app_name => app['shortname'],
        :enable_ssl => enable_ssl,
        :ssl_key => ssl_key,
        :ssl_ca => ssl_ca,
        :ssl_cert => ssl_cert,
        :multisite => app['environment']['MULTISITE'],
        :http_auth => http_auth
      )
    end

    execute "reload-nginx-php" do
      command "nginx -t && service nginx reload && service php7.0-fpm restart"
      action :nothing
    end
  
  end
end
