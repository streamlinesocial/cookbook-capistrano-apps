# the data bag name and item key to use for finding deploy user data
# default["capistrano"]["deploy_user"]["data_bag_name"] = "users"
# default["capistrano"]["deploy_user"]["data_bag_key"] = "deploy"

# username of the deploy user account
default["capistrano"]["deploy_user"] = "deploy"

# root of the directory to setup for deploy users
default["capistrano"]["deploy_to_root"] = "/opt/apps"

# stores data for apps
# @TODO: use data bags for this
default["apps"] = []

# where to store ssl certs from lets encrypt
default["capistrano"]["letsencrypt"]["cert_dir"] = "/etc/letsencrypt/live"

# the version of mysql to use when using recipe::app_mysql
default["capistrano"]["mysql"]["service_version"] = "5.6"
