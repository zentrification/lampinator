require 'logger'
require 'tilt'
require 'yaml'

# monkey patch string so we can be lazy about
# trailing slashes in yaml config files
class String
  def add_trailing_slash
    self.reverse[0].eql?('/') ? self : self + '/'
  end
end

# log to logfile and stdout
class MultiIO
  def initialize(*targets)
     @targets = targets
  end

  def write(*args)
    @targets.each {|t| t.write(*args)}
  end

  def close
    @targets.each(&:close)
  end
end

log_file = File.open("log.txt", "a")
$log = Logger.new MultiIO.new(STDOUT, log_file)

# config
# ------------------------------
global = YAML.load_file 'global.yml'
sites = YAML.load_file 'sites.yml'

docroot = global['apache']['docroot'].add_trailing_slash
apache_vhosts = global['apache']['vhosts'].add_trailing_slash

vhost_template = Tilt::ERBTemplate.new('templates/vhost.erb')

# iterate sites and do everything
sites.each_key do |key|

  # sanity checks
  filename = apache_vhosts.to_s + sites[key]['apache']['domain'].to_s
  domain_check = `egrep #{sites[key]['apache']['domain']} /etc/apache2/sites-available/*`
  unless domain_check.empty?
    $log.error 'Error: domain already in use'
    $log.error domain_check
    exit
  end

  if FileTest.exists? filename
    $log.error 'Error: apache configuration file already exists'
    $log.error filename
    exit
  end

  # render the apache vhost configuration file
  output = vhost_template.render(self, { 
    :aliases => sites[key]['apache']['aliases'],
    :allowoverride => sites[key]['apache']['htaccess'].eql?('no') ? 'None' : 'All',
    :docroot => docroot.to_s + sites[key]['apache']['domain'],
    :domain => sites[key]['apache']['domain']
  })
  vhost_file = File.open(filename, 'w')
  vhost_file.puts output
  vhost_file.close
  $log.info 'Apache configuration file written'
  $log.info filename

  # enable apache configuration file and restart apache
  system("a2ensite #{sites[key]['apache']['domain']}")
  system("service apache2 reload")
end


# site_name:
#   domain:
#     primary: example.com
#     aliases:
#       - example.net
#       - example.org
#       - example-mirror.org
#   database:
#     name: example_db_name
#     user: example_user
#     password: example_password
#   files:
#     db_dump: filename.sql
#     docroot_zip: files.zip
# 
