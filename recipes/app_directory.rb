include_recipe "capistrano-apps::default"

deploy_user = 'deploy'

# app deploy directory, e.g. /opt/apps
directory node["capistrano"]["deploy_to_root"] do
    owner deploy_user
    group deploy_user
    recursive true
end

node["apps"].each do |app_name,app|

    #
    # http://www.elabs.se/blog/57-handle-secret-credentials-in-ruby-on-rails
    # http://stackoverflow.com/questions/15411817/get-environment-variables-in-symfony2-parameters-yml
    #

    # setup directory for app to be installed to, including a 'shared' dir that is
    # used by capistrano style deploys
    [ "#{node['capistrano']['deploy_to_root']}/#{app_name}",
      "#{node['capistrano']['deploy_to_root']}/#{app_name}/shared"
    ].each do |dir|
        directory dir do
            owner deploy_user
            group deploy_user
        end
    end

    # install packages for the application
    if app.has_key? 'packages'
        app['packages'].each do |pkg|
            package pkg do
                action :install
            end
        end
    end

    if app.has_key? 'properties'
        # setup a build.properties file into the shared dir that can be used
        # by build scripts by apps
        template "#{node['capistrano']['deploy_to_root']}/#{app_name}/shared/build.properties" do
            action :create_if_missing
            source "build.properties.erb"
            owner deploy_user
            group deploy_user
            mode "644"
            variables({
              "properties" => app['properties']
            })
        end
    end
end
