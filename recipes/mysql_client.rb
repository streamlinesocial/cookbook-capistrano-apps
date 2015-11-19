# use the mysql cookbook to install the mysql libs
mysql_client 'default' do
    action :create
end
