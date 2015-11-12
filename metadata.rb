name             'capistrano-apps'
maintainer       'Streamline Social'
maintainer_email 'support@streamlinesocial.com'
license          'Apache 2.0'
description      'Sets up space for use of Capistrano v3 to deploy, lots of assumptions around a LAMP stack (at least currently.)'
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          '1.2.0'

depends 'user'
depends 'database'
depends 'memcached'
