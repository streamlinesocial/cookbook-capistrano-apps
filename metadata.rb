name             'capistrano-apps'
maintainer       'Streamline Social'
maintainer_email 'support@streamlinesocial.com'
license          'Apache 2.0'
description      'Sets up space for use of Capistrano v3 to deploy, lots of assumptions around a LAMP stack (at least currently.)'
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          '2.1.1'

depends 'user'
depends 'memcached', '~> 2.0.0'
depends 'mysql2_chef_gem', '>= 1.0.1'
depends 'mysql', '~> 7.2.0'
depends 'database', '>= 4.0.3'
