UrlUtils = require 'url'
redis = require 'redis'

module.exports = class RedisStore
  constructor: (options) ->
    {url, port, host, password, @timeout} = options
    if url
      parsed_url = UrlUtils.parse(url)
      port = parsed_url.port
      host = parsed_url.hostname
      password = parsed_url.auth?.split(':')[1]

    @client = redis.createClient(port, host)
    @client.auth(password) if password

  set: (key, value, callback) =>
    if @timeout
      @client.psetex(key, @timeout, JSON.stringify(value), callback)
    else
      @client.set(key, JSON.stringify(value), callback)

  get: (key, callback) =>
    @client.get key, (err, result) =>
      return callback(err) if err
      callback(null, JSON.parse(result))

  destroy: (key, callback) =>
    @client.del(key, callback)

  del: @destroy

  reset: (callback) -> callback()
