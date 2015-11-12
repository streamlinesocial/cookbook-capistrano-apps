include_recipe "capistrano::default"

# unless Chef::Config[:solo]
unless node["capistrano"]["deploy_user"].has_key?("account")
    # get the data bag item of the user we deploy as
    key = node["capistrano"]["deploy_user"]["data_bag_key"]
    bag = node["capistrano"]["deploy_user"]["data_bag_name"]
    u = data_bag_item(bag, key.gsub(/[.]/, '-'))
    deploy_user = key || u['id']
else
    deploy_user = node["capistrano"]["deploy_user"]["account"]
end

# ensure apache and deploy_user are in each others groups for permissions reasons
unless node["apache"].nil?
    # add deploy_user to apache group (helps when deploy needs to
    # clear cache / files created by apache)
    group node["apache"]["group"] do
        members deploy_user
        append true
    end

    # add apache to deploy_user group (this is the common required
    # action to let apache serve files owned by deploy_user)
    group deploy_user do
        members node["apache"]["user"]
        append true
    end
end

# ensure the default site is not enabled
apache_site "default" do
    enable false
end

# configure the apps
node["apps"].each do |app_name,app|

    # only setfacl if apache and deploy user are not the same, not required if they are
    unless node["apache"]["user"] == deploy_user
        # ensure that ACL is setup for apps so apache and the deploy user can both interact with
        # the files created by each other. common use case for this is symfony, it creates cache
        # files with no group write, but with acl, groups can then be set to write on it
        #
        # setfacl -R  -m u:apache:rwX -m u:deploy:rwX /opt/apps/app-name_env
        # setfacl -dR -m u:apache:rwX -m u:deploy:rwX /opt/apps/app-name_env
        execute "capistrano-directory-setfacl-set-initial" do
            action :nothing
            command "setfacl -R -m u:#{node["apache"]["user"]}:rwX -m u:#{deploy_user}:rwX #{node['capistrano']['deploy_to_root']}/#{app_name}"
            subscribes :run, "directory[#{node['capistrano']['deploy_to_root']}/#{app_name}]", :immediately
        end

        execute "capistrano-directory-setfacl-set-default" do
            action :nothing
            command "setfacl -dR -m u:#{node["apache"]["user"]}:rwX -m u:#{deploy_user}:rwX #{node['capistrano']['deploy_to_root']}/#{app_name}"
            subscribes :run, "directory[#{node['capistrano']['deploy_to_root']}/#{app_name}]", :immediately
        end
    end

    if app.has_key? 'apache'
        if app["apache"].has_key? 'vhost'

            vhost = app["apache"]["vhost"]

            # create virtual host entry for apache
            web_app app_name do
                if vhost.has_key? 'cookbook' and vhost.has_key? 'template'
                    cookbook vhost['cookbook']
                    template vhost['template']
                else
                    template 'vhost.conf.erb'
                end

                if vhost.has_key? 'port'
                    server_port vhost['port']
                else
                    server_port 80
                end

                # document root is in the cap deploy path for the app, current symlink, and into the defined app web root
                docroot "#{node['capistrano']['deploy_to_root']}/#{app_name}/current/#{vhost['docroot']}"
                server_name app_name
                server_aliases vhost['aliases']
                server_is_canonical vhost['is_canonical']
                enable true
            end

            # # note: this SSL install may need to be tweaked, but this is an example of what would need to be done
            # # install ssl certs if listening to 443
            # if node['apache']['listen_ports'].include?("443")
            #     # create ssl dir for where we place certs
            #     %w{ /etc/httpd/ssl/ssl.crt /etc/httpd/ssl/ssl.key }.each do |dirname|
            #         directory dirname do
            #             action :create
            #             recursive true
            #         end
            #     end
            #     # install the key file
            #     cookbook_file "/etc/httpd/ssl/ssl.key/#{app_name}.key" do
            #         backup false
            #         source "ssl/server.key" # this is the value that would be inferred from the path parameter
            #         mode "0644"
            #     end
            #     # install server cert
            #     cookbook_file "/etc/httpd/ssl/ssl.crt/#{app_name}.crt" do
            #         backup false
            #         source "ssl/WWW.DOMAIN.COM.crt" # this is the value that would be inferred from the path parameter
            #         mode "0644"
            #     end
            #     # this file is needed too
            #     cookbook_file "/etc/httpd/ssl/ssl.key/Apache_Plesk_Install.txt" do
            #         source "ssl/Apache_Plesk_Install.txt" # this is the value that would be inferred from the path parameter
            #         mode "0644"
            #         backup false
            #     end
            # end
        end
    end
end
