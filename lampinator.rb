require 'logger'
require 'tilt'
require 'yaml'
require File.dirname(__FILE__) + '/lib/apache.rb'
require File.dirname(__FILE__) + '/lib/mysql.rb'
require File.dirname(__FILE__) + '/lib/util.rb'

# logging
# ------------------------------ 
log_file = File.open("log.txt", "a")
$log = Logger.new MultiIO.new(STDOUT, log_file)
$log.formatter = Proc.new do |severity, time, progname, msg|
  message = severity.to_s + ":\t" + msg.to_s + "\r\n"
  $stderr.puts message if severity == 'ERROR'
  message
end

# config
# ------------------------------
global = YAML.load_file 'config/global.yml'
sites = YAML.load_file 'config/sites.yml'

docroot = global['apache']['docroot'].add_trailing_slash
apache_vhosts = global['apache']['vhosts'].add_trailing_slash

# iterate sites
# configure portions specified in yaml
# ------------------------------
sites.each_key do |key|
  Apache.configure(docroot, apache_vhosts, sites[key]['apache']) if sites[key]['apache']
  Mysql.configure('localhost', 'root', '', sites[key]['mysql']) if sites[key]['mysql']
end


# site_name:
#   domain:
#     primary: example.com
#     aliases:
#       - example.net
#       - example.org
#       - example-mirror.org
#   mysql:
#     database: example_db_name
#     user: example_user
#     password: example_password
#   files:
#     db_dump: filename.sql
#     docroot_zip: files.zip
# 
