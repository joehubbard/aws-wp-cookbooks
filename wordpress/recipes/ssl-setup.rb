user = 'ubuntu'

search("aws_opsworks_app").each do |app|

  if app['deploy']
  
        if app['enable_ssl'] == true
      
      template "/etc/ssl/#{app['domains'].first}.crt" do
        mode '0640'
        owner "root"
        group "www-data"
        source "ssl.key.erb"
        variables :key => app['ssl_configuration']['certificate']
        only_if do
          app['enable_ssl'] && app['ssl_configuration']['certificate']
        end
      end

      template "/etc/ssl/#{app['domains'].first}.key" do
        mode '0640'
        owner "root"
        group "www-data"
        source "ssl.key.erb"
        variables :key => app['ssl_configuration']['private_key']
        only_if do
          app['enable_ssl'] && app['ssl_configuration']['private_key']
        end
      end

      template "/etc/ssl/#{app['domains'].first}.ca" do
        mode '0640'
        owner "root"
        group "www-data"
        source "ssl.key.erb"
        variables :key => app['ssl_configuration']['chain']
        only_if do
          app['enable_ssl'] && app['ssl_configuration']['chain']
        end
      end
      
      ssl_crt = "/etc/ssl/#{app['domains'].first}.crt",
      ssl_key = "/etc/ssl/#{app['domains'].first}.key",
      ssl_ca = "/etc/ssl/#{app['domains'].first}.ca"
      
    end
    
    if app['environment']['CERTBOT']
      
      execute "certbot" do
        command "certbot certonly --webroot -w #{release_dir}web -d #{domains_cert} --agree-tos --email james.hall@impression.co.uk --non-interactive"
      end
      
      ssl_crt = "/etc/letsencrypt/live/#{app['domains'].first}/cert.pem",
      ssl_key = "/etc/letsencrypt/live/#{app['domains'].first}/privkey.pem",
      ssl_ca = "/etc/letsencrypt/live/#{app['domains'].first}/fullchain.pem"
      
      template "/etc/cron.daily/certbot" do
        source "daily-cron.erb"
        owner "root"
        group "root"
        mode "644"
      end
      
    end
    
    enable_ssl = true
    app_name = app['domains'].pop()
    domains = app['domains'].join(" ")
    
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
        :ssl_crt => "/etc/ssl/#{app['domains'].first}.crt",
        :ssl_key => "/etc/ssl/#{app['domains'].first}.key",
        :ssl_ca => "/etc/ssl/#{app['domains'].first}.ca",
        :multisite => app['environment']['MULTISITE'],
        :http_auth => http_auth
      )
    end
  
  end
end
