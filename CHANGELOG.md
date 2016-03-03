capistrano CHANGELOG
====================

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

