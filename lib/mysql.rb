module Mysql
  def Mysql.configure(host, user, password, config)
    # options string not working correctly when there is no password
    options = "-h #{host} -u #{user} -p#{password}"

    sanity checks
    query = "SELECT SCHEMA_NAME FROM INFORMATION_SCHEMA.SCHEMATA WHERE SCHEMA_NAME = '" + config['database'] + "'"
    unless `mysql #{options} -e "#{query}"`.empty?
      $log.error 'Mysql database already exists'
      exit
    end
    query = "select * from mysql.user where user = '" + config['user'] + "'"
    unless `mysql #{options} -e "#{query}"`.empty?
      $log.error 'Mysql user already exists'
      exit
    end

    `mysql #{options} -e "create database #{config['database']}"`
    query = "create user #{config['user']}@'localhost' identified by '#{config['password']}'"
    `mysql #{options} -e "#{query}"`
    query = "grant all privileges on #{config['database']}.* to #{config['user']}@'localhost'"
    `mysql #{options} -e "#{query}"`
  end
end
