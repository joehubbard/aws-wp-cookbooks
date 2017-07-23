user = 'ubuntu'

search("aws_opsworks_app").each do |app|

  if app['deploy']

    db = node['deploy']['wp']['database']
    

  end

end
