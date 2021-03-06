capistrano CHANGELOG
====================

4.0.4
-----

- Default mailto to '' for all cron jobs

4.0.3
-----

- Add ability to override the deploy user via attribute again
- Remove old reference to deploy user data bag
- Fix setfacl calls on directory creation based on attrib settings

4.0.2
-----

- Fix check for skip\_setfacl to ensure setfacl is run in more cases where it should be

4.0.1
-----

- Use chef group not users\_manage to create deploy user, to avoid deleting 'apache' user from deploy group in chef runs to only add it back in the same chef run

4.0.0
-----

- Major bumps in versions in dependant cookbooks
- Added depends for cookbook yum-mysql-community (per mysql cookbook change)

3.0.0
-----

- BREAKING CHANGE: Switch to use cookbook 'users' rather than 'user'
- BREAKING CHANGE: Switch to use cookbook 'memcached' v3.x from v2.x

2.1.2
-----

- Lock apache2 cookbook at v7. v8 introduces breaking changes related to yum and mysql.

2.1.1
-----

- Fix calls to initial 'letsencrypt' email param
- Be sure to stop apache and restart after cert creation to allow us to use the --standalone flag on port 80/443

2.1.0
-----

- Added ability to use 'letsencrypt' to generate SSL certs automatically

2.0.1
-----

- Fix acl apache/deploy group permissions on app directories (there were cases where the default acl's were
  not set on the deploy dir.)

2.0.0
-----

BREAKING CHANGES:

- Using memcached cookbook ~> 2.0.0, which changes cookbook name for config

1.2.1
-----

- work around for mysql2_chef_gem with chef >= 12.5 @see https://github.com/sinfomicien/mysql2_chef_gem/issues/5

1.2.0
-----

- make deploy user config vagrant / chef solo friendly, so that we can use chef solo to configure
  local deploy test environments easily
- move setfacl to the app loop in apache recipe, so that each app directory gets the setfacl call
  rather than the root directory as a whole. this allows for a vagrant share or mount to be used
  for one dir while a native dir used for the next

1.1.1
-----

- Disable the SSL config from the vhost by default. SSL can be used by overriding the template in a separate cookbook.

1.1.0
-----

- Skip running setfacl in situations its not needed, mainly in vagrant env with nfs drives
- Add ability to manage deploy keys per [node,environment,role] with node attributes
- Added support for chef-solo environments without requiring data_bags for users.

1.0.0
-----
- Reworked to be app driven and more segmented, now each service has an individual recipe.

0.1.0
-----
- Initial release of capistrano cookbook.

