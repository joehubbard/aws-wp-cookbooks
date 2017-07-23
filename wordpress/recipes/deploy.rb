user = 'ubuntu'

search("aws_opsworks_app").each do |app|

  if app['deploy']

    db = node['deploy']['wp']['database']
    domains = app['domains'].join(" ")
    wp_home =  app['environment']['WP_HOME'];
    if app['environment']['MULTISITE']
      site_url = wp_home
    else
      site_url = "#{wp_home}/wp"
    end
    site_root = "/var/www/#{app['shortname']}/"
    shared_dir = "/efs/#{app['shortname']}/shared/"
    current_link = "#{site_root}current"
    time =  Time.new.strftime("%Y%m%d%H%M%S")
    release_dir = "#{site_root}releases/#{time}/"
    theme_dir = "#{release_dir}web/app/themes/#{app['environment']['THEME_NAME']}/"
      
  end

end
