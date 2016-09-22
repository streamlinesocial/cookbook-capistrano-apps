include_recipe "capistrano-apps::default"

deploy_user = node['capistrano']['deploy_user']

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

    if app.has_key? 'apache'

        # only setfacl if apache and deploy user are not the same, not required if they are
        unless (node["apache"]["user"] === deploy_user) || (app['apache'].has_key? 'skip_setfacl' && app['apache']['skip_setfacl'] === true)
            # ensure that ACL is setup for apps so apache and the deploy user can both interact with
            # the files created by each other. common use case for this is symfony, it creates cache
            # files with no group write, but with acl, groups can then be set to write on it
            #
            # sudo setfacl -R  -m u:apache:rwX -m u:deploy:rwX /opt/apps/app-name_env
            # sudo setfacl -dR -m u:apache:rwX -m u:deploy:rwX /opt/apps/app-name_env
            #
            # always run this, to ensure proper permissions
            execute "capistrano-directory-setfacl-set-initial" do
                action :run
                command "setfacl -R -m u:#{node["apache"]["user"]}:rwX -m u:#{deploy_user}:rwX #{node['capistrano']['deploy_to_root']}/#{app_name}"
                subscribes :run, "directory[#{node['capistrano']['deploy_to_root']}/#{app_name}]", :immediately
            end

            # always run this, to ensure proper permissions
            execute "capistrano-directory-setfacl-set-default" do
                action :run
                command "setfacl -dR -m u:#{node["apache"]["user"]}:rwX -m u:#{deploy_user}:rwX #{node['capistrano']['deploy_to_root']}/#{app_name}"
                subscribes :run, "directory[#{node['capistrano']['deploy_to_root']}/#{app_name}]", :immediately
            end
        end

        if app["apache"].has_key? 'vhost'

            vhost = app["apache"]["vhost"]
            # document root is in the cap deploy path for the app, current symlink, and into the defined app web root
            docroot_full = "#{node['capistrano']['deploy_to_root']}/#{app_name}/current/#{vhost['docroot']}"

            # get decide if we use https or http
            if vhost.has_key? 'canonical_protocol'
                server_canonical_protocol = vhost['canonical_protocol']
            else
                server_canonical_protocol = 'http'
            end

            # build a domain that we can use as a full url
            if vhost.has_key? 'canonical_domain'
                server_canonical_domain = vhost['canonical_domain']
                server_canonical_url = "#{server_canonical_protocol}://#{vhost['canonical_domain']}"
            else
                server_canonical_domain = vhost['canonical_domain']
                server_canonical_url = false
            end

            # used to setup email for SSL cert validation
            if vhost.has_key? 'letsencrypt_email'
                letsencrypt_email = vhost['letsencrypt_email']
            else
                letsencrypt_email = false
            end

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

                docroot docroot_full
                server_name app_name
                server_aliases vhost['aliases']
                server_is_canonical vhost['is_canonical']
                server_canonical_domain server_canonical_domain
                server_canonical_url server_canonical_url
                server_canonical_protocol server_canonical_protocol
                enable true
            end

            # runs only if we have been told to run letsencrypt, and if we have a letsencrypt email
            if vhost.has_key? 'letsencrypt'
                if vhost['letsencrypt']
                    if letsencrypt_email

                        # make sure the directory exists, as this script will probably run before the app is installed with capistrano
                        directory docroot_full do
                            action :create
                            owner 'deploy'
                            group 'deploy'
                            recursive true
                        end

                        ssl_cert_domains = [server_canonical_domain] + vhost['aliases']

                        file "#{node['capistrano']['deploy_to_root']}/#{app_name}/shared/letsencrypt.log" do
                            content "#{node['capistrano']['deploy_to_root']}/letsencrypt/current/letsencrypt-auto certonly --standalone --agree-tos --email #{letsencrypt_email} -w #{docroot_full} -d #{ssl_cert_domains.join(' -d ')}"
                            mode '0755'
                            owner 'deploy'
                            group 'deploy'
                        end

                        deploy 'letsencrypt' do
                            repo 'https://github.com/letsencrypt/letsencrypt'
                            deploy_to "#{node['capistrano']['deploy_to_root']}/letsencrypt"
                            action :deploy
                            purge_before_symlink []
                            create_dirs_before_symlink []
                            symlinks({})
                            symlink_before_migrate({})
                        end

                        # create ssl dir for where we place certs
                        %w{ /etc/httpd/ssl }.each do |dirname|
                            directory dirname do
                                action :create
                                recursive true
                            end
                        end

                        cert_install_dir  = "#{node["capistrano"]["letsencrypt"]["cert_dir"]}/#{server_canonical_domain}"

                        # need to halt the web server first
                        log "free port 80/443 for letsencrypt - stop apache2" do
                            notifies :stop, 'service[apache2]', :immediately
                            not_if { File.exists?("#{cert_install_dir}/fullchain.pem") }
                        end

                        execute 'install_ssl_letsencrypt' do
                            command "#{node['capistrano']['deploy_to_root']}/letsencrypt/current/letsencrypt-auto certonly --standalone --agree-tos --email  #{letsencrypt_email} -w #{docroot_full} -d #{ssl_cert_domains.join(' -d ')}"
                            action :run
                            cwd "/etc/httpd/ssl"
                            not_if { File.exists?("#{cert_install_dir}/fullchain.pem") }
                        end

                        log "ensure start apache2" do
                            notifies :start, 'service[apache2]'
                        end

                        # copy the certs to a place we want them to be
                        link "/etc/httpd/ssl/#{server_canonical_domain}.key" do
                            to "#{cert_install_dir}/privkey.pem"
                        end
                        link "/etc/httpd/ssl/#{server_canonical_domain}.crt" do
                            to "#{cert_install_dir}/cert.pem"
                        end
                        link "/etc/httpd/ssl/#{server_canonical_domain}.chain.crt" do
                            to "#{cert_install_dir}/chain.pem"
                        end

                    else
                        file "#{node['capistrano']['deploy_to_root']}/#{app_name}/shared/letsencrypt.log" do
                            content 'We would NOT have run letsencrypt'
                            mode '0755'
                            owner 'deploy'
                            group 'deploy'
                        end
                    end
                end
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
