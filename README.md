capistrano Cookbook
===================
Creates the required infrastructure to enalbe capistrano deployments. Things like
creating a deploy user and ensuring proper group additions etc are made.

Usage
=====

Add the use of the recipes to the node or include them via another cookbook. The recipes all
draw their configs from a node['capistrano'] and node['apps'] attribs from the node / env.

Data Bag
========

```
knife data bag create users
knife data bag create users deploy
```

```
{
  "id": "deploy",
  "groups": [
    "deploy",
    "sysadmin"
  ],
  "home": "/home/deploy",
  "ssh_keys": [
    "ssh-rsa PUBLIC-KEY-HERE",
    "ssh-rsa ANOTHER-PUBLIC-KEY-HERE..."
  ]
}

```

Node Attributes
===============

Example: (node attributes)

```
"apps": {
    "app_name_env": {
        "databases": {
            "mysql": [
                {
                    "name": "db_name",
                    "user": "db_user_env",
                    "pass": "db_pass"
                }
            ]
        },
        "apache": {
            "vhost": {
                "cookbook": "site_database",
                "template": "vhost.conf.erb",
                "docroot": "public/web",
                "aliases": [ "app.com", "www.app.com", "192.237.181.31"],
                "is_canonical": false
            }
        },
    }
}
```

To use the values, ensure the recipes that drive the servies are in the
nodes run list somewhere, either directly on the node, or included via
a site-cookbook recipe.

Example: node.json attribs

```
"run_list": [
    "recipe[capistrano-apps::app_directory]",
    "recipe[capistrano-apps::app_mysql]"
]
```

Example: site cookbook recipe.rb

```
include_recipe "capistrano-apps::app_apache"
include_recipe "capistrano-apps::app_mysql"
include_recipe "capistrano-apps::app_crons"

# from here, the node attributes can be defined here or on the node
```

Default
-------

Configures the deploy user.

Directory
---------

Ensures the deploy user owns a directory somewhere that acts as the root file system
for apps deployed by that user (e.g. /opt/apps.)

Apache
------

Configures the relationship between deploy user/group and apache user/group. Also
this recipe adds the vhosts as defined in the attributes.

```
"apache": {
    "vhost": {
        "cookbook": "custom_site_cookbook",
        "template": "vhost.conf.erb",
        "docroot": "public/web",
        "aliases": [ "app.com", "www.app.com", "192.237.181.31"],
        "is_canonical": false
    }
},
```

MySQL
-----

Creates the mysql databases defined in the attributes.

```
"databases": {
    "mysql": [
        {
            "name": "db_name",
            "user": "db_user_env",
            "pass": "db_pass"
        }
    ]
},
```

Memcache
--------

Creates memcache pools defined in the node attributes.

```
"memcache_pools": {
    "sessions": {
        "name": "sessions",
        "port": "11211",
        "memory": "16"
    },
    "doctrine": {
        "name": "doctrine",
        "port": "11212",
        "memory": "8"
    }
},
```

Crons
-----

Creates cron jobs defined in the node attributes.

Note: Cron commands are altered to use the 'current' directory as the root.

Todo: Enable a cron to define it's root, so we don't need to depend
on the 'app_directory' recipe.

```
"crons": {
    "smsdelivery": {
        "minute": "*/5",
        "hour": "*",
        "day": "*",
        "month": "*",
        "weekday": "*",
        "action": "create",
        "command": "php public/app/console smsqueuebundle:buffer:deliver"
    },
    "cronbundle": {
        "minute": "*/5",
        "hour": "*",
        "day": "*",
        "month": "*",
        "weekday": "*",
        "action": "create",
        "command": "php bin/phing cron:run"
    }
},
```

Full Example
============

```
    "apps": {
      "appname_dev": {
        "properties": {
          "database.name": "db_dev",
          "database.user": "root",
          "database.pass": "",
          "some.app.var": "cho",
        },
        "apache": {
          "vhost": {
            "docroot": "public/web",
            "aliases": [
              "app.dev",
              "www.app.dev"
            ],
            "is_canonical": false,
            "canonical_domain": "www.app.dev",
            "cookbook": "WRAPPER-COOKBOOK-NAME",
            "template": "file.in.wrapper.cookbook.vhost.conf.erb",
            "canonical_url": "www.app.dev",
            "canonical_protocol": "https"
          }
        },
        "databases": {
          "mysql": [
            {
              "name": "app_dev",
              "user": "root",
              "pass": ""
            }
          ],
          "mysql_service": {
            "server_root_password": ""
          }
        }
      }
    },
    "apache": {
      "server_ssl_listen_ip": "192.168.6.60",
      "listen": [
        "*:80",
        "*:443"
      ]
    }
```
