# the data bag name and item key to use for finding deploy user data
default["capistrano"]["deploy_user"]["data_bag_name"] = "users"
default["capistrano"]["deploy_user"]["data_bag_key"] = "deploy"
default["capistrano"]["deploy_to_root"] = "/opt/apps"

default["apps"] = []

# default["capistrano"]["mysql_client"]["packages"] = ["mysql55"]
