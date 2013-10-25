store-redis
===========

A simple redis store for backbone-orm's query caching

### options

  * host: Your redis server hostname
  * port: Your redis server port
  * password: A password to use for auth with redis
  * url: An url with connection information if you prefer that. Username will not be used if present, but a password will e.g. redis://unused:password@localhost:6379/
  * redis_options: Options to be passed to the redis client
  * timeout: If present psetex will be used with this value for every set command. If not given a standard set is used (keys will not be volatile)
