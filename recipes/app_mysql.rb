node["apps"].each do |app_name,app|

    # if we have any databases check for mysql database settings
    if app.has_key? 'databases'

        # ensure mysql is running if we need to define a service
        if app["databases"].has_key? 'mysql_service'
            mysql_service app_name do
                port '3306'
                version '5.5'
                initial_root_password app['databases']['mysql_service']['server_root_password']
                action [:create, :start]
            end
        end

        # create the databases for the mysql service
        if app["databases"].has_key? 'mysql'

            # configure the mysql2 ruby gem.
            mysql2_chef_gem 'default' do
                provider Chef::Provider::Mysql2ChefGem::Mysql
                action :install
            end

            # configure the MySQL client.
            mysql_client 'default' do
                action :create
            end

            # create each mysql database
            app['databases']['mysql'].each do |app_db|

                # ensure mysql is running
                # service 'mysql' do
                #     action :enable
                # end

                # setup database create auth
                mysql_connection_info = {
                    :host => "127.0.0.1",
                    :username => 'root',
                    :password => app['databases']['mysql_service']['server_root_password']
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


