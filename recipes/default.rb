# unless Chef::Config[:solo]
unless node["capistrano"]["deploy_user"].has_key?("account")
    # get the data bag item of the user we deploy as
    key = node["capistrano"]["deploy_user"]["data_bag_key"]
    bag = node["capistrano"]["deploy_user"]["data_bag_name"]

    # taken from user::data_bag recipe, we want to manually ensure our
    # user exists but we'll use data from the data_bag. That way we don't
    # need to alter the node['users'] array to use this cookbook. But we
    # still get a native system user account.
    u = data_bag_item(bag, key.gsub(/[.]/, '-'))
    deploy_user = key || u['id']

    user_account deploy_user do
        # switch - enable granular ssk_keys per node/env
        unless node["capistrano"].has_key?("deploy_keys")
            # default - setup user with global deploy users ssh_keys
            %w{comment uid gid home shell password system_user manage_home create_group ssh_keys ssh_keygen}.each do |attr|
                send(attr, u[attr]) if u[attr]
            end
        else
            # if provided deploy keys via node attribs, use them for ssh_keys
            %w{comment uid gid home shell password system_user manage_home create_group ssh_keygen}.each do |attr|
                send(attr, u[attr]) if u[attr]
            end
            send("ssh_keys", node["capistrano"]["deploy_keys"])
        end

        action u['action'].to_sym if u['action']
    end

    unless u['groups'].nil?
        u['groups'].each do |groupname|
            group groupname do
                members deploy_user
                append true
            end
        end
    end
end
