include_recipe "capistrano-apps::app_directory"

unless Chef::Config[:solo]
    # get the data bag item of the user we deploy as
    key = node["capistrano"]["deploy_user"]["data_bag_key"]
    bag = node["capistrano"]["deploy_user"]["data_bag_name"]
    u = data_bag_item(bag, key.gsub(/[.]/, '-'))
    deploy_user = key || u['id']
else
    deploy_user = node["capistrano"]["deploy_user"]["account"]
end

node["apps"].each do |app_name,app|

    if app.has_key? 'crons'

        # setup cron jobs based on the attributes for this symfony node
        app['crons'].each do |cron_key,values|

            # set defaults so we don't break the loop
            defaults = {
                'user'    => deploy_user,
                'minute'  => '*',
                'hour'    => '*',
                'day'     => '*',
                'month'   => '*',
                'weekday' => '*',
                'action'  => 'create'
            }

            # leave 'command' out of defaults, its considered a required and we want chef to crash to indicate as such

            # merge values overwriting defaults
            values = defaults.merge(values)

            # alter the command to be rooted in the apps deploy directory
            values['command'] = "cd #{node['capistrano']['deploy_to_root']}/#{app_name}/current; #{values['command']}"

            # use key as a suffix for the cron name
            cron "app_#{app_name}_#{cron_key}" do
                user        values['user']
                minute      values['minute']
                hour        values['hour']
                day         values['day']
                month       values['month']
                weekday     values['weekday']
                command     values['command']

                # define the create or delete
                case values['action']
                when 'delete'
                    action :delete
                else
                    action :create
                end
            end
        end
    end
end

