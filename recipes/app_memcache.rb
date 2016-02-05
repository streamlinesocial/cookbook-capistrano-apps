include_recipe "memcached"

node["apps"].each do |app_name,app|

    # create a 'bucket' for memcache for each pool defined
    if app.has_key? 'memcache_pools'
        # setup memcache
        app['memcache_pools'].each do |memcached_key,values|
            memcached_instance "memcache-#{values['name']}" do
                port values['port']
                memory values['memory']
            end
        end
    end

end
