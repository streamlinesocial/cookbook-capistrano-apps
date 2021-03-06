#
# in version 2.x, this cookbook allowed us to override the 'deploy' user's authorized_hosts (ssh_keys)
# and add specific users per env. we want to still allow that override, but in version 3.x, we switched
# to use the 'users' cookbook over the 'user' cookbook
#
# now, we rely on the data bag for the deploy user to setup most of this, and we'll just override the
# ssh_keys property at this point
#
# another breaking change from v2.x is that we drop the ability to operate with no data bag support.
# old version of chef-solo required us to work with no data_bags, however now we assume chef_zero or
# chef_client, and assume that data_bags are not a problem

group 'deploy' do
    action [:create]
    gid 3000
    members 'deploy'
    append true
end

# users_manage 'deploy' do
#     group_id 3000
#     action [:create]
# end

# unless Chef::Config[:solo]
#     # get the data bag item of the user we deploy as
#     key = node["capistrano"]["deploy_user"]["data_bag_key"]
#     bag = node["capistrano"]["deploy_user"]["data_bag_name"]
#     u = data_bag_item(bag, key.gsub(/[.]/, '-'))
#     deploy_user = key || u['id']
# else
#     deploy_user = node["capistrano"]["deploy_user"]["account"]
# end
