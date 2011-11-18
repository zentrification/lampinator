module Apache
  def Apache.configure(docroot, apache_vhosts, config)
    # sanity checks
    # is the domain being hosted already?
    filename = apache_vhosts + config['domain']
    domain_check = `grep -l #{config['domain']} #{apache_vhosts}*`
    unless domain_check.empty?
      $log.error 'Domain already in use'
      $log.error ' ' + domain_check
      exit
    end

    # does config file exist already?
    if FileTest.exists? filename
      $log.error 'Apache configuration file already exists'
      $log.error ' ' + filename
      exit
    end

    # render the apache vhost configuration file
    template = Tilt::ERBTemplate.new('templates/vhost.erb')
    output = template.render(self, {
      :aliases => config['aliases'],
      :allowoverride => config['htaccess'].eql?('no') ? 'None' : 'All',
      :docroot => docroot + config['domain'],
      :domain => config['domain']
    })
    vhost_file = File.open(filename, 'w')
    vhost_file.puts output
    vhost_file.close
    $log.info 'Apache configuration file written'
    $log.info ' ' + filename

    # enable apache configuration file and restart apache
    $log.info 'Enabling apache configuration file'
    if system("a2ensite #{config['domain']}")
      $log.info ' success'
    else
      $log.error ' apache did not enable new configuration properly'
    end
    $log.info 'Reloading apache configuration'
    if system("service apache2 reload")
      $log.info ' success'
    else
      $log.error ' apache did not reload properly'
    end
  end
end
