include_recipe "database::mysql"

node["apps"].each do |app_name,app|

    # if we have any databases check for mysql database settings
    if app.has_key? 'databases'
        if app["databases"].has_key? 'mysql'
            # create each mysql database
            app['databases']['mysql'].each do |app_db|

                # ensure mysql is running
                service 'mysql' do
                    action :enable
                end

                # setup database create auth
                mysql_connection_info = {
                    :host => "localhost",
                    :username => 'root',
                    :password => node['mysql']['server_root_password']
                }

                # create database for the environment
                database app_db['name'] do
                    provider Chef::Provider::Database::Mysql
                    connection mysql_connection_info
                    action :create
                end

                # only create the database user if it's not the root user
                unless app_db['user'] == 'root'
                    %w{ localhost 127.0.0.1 }.each do |mysql_remote_host|
                        mysql_database_user app_db['user'] do
                            connection mysql_connection_info
                            password app_db['pass']
                            database_name app_db['name']
                            host mysql_remote_host
                            action :grant
                        end
                    end
                end
            end
        end
    end
end


