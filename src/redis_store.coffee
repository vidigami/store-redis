_ = require 'underscore'
moment = require 'moment'
UrlUtils = require 'url'
redis = require 'redis'

module.exports = class RedisStore
  constructor: (options) ->
    {url, port, host, password, redis_options, @timeout} = options
    if url
      parsed_url = UrlUtils.parse(url)
      port = parsed_url.port
      host = parsed_url.hostname
      password = parsed_url.auth?.split(':')[1]

    @client = redis.createClient(port, host, redis_options)
    @client.auth(password) if password

  hset: (hash, key, value, callback) =>
    if value
      value = {value: value, _redis_set_at: moment().utc().toDate().toISOString()}
    @client.hset(hash, key, JSON.stringify(value), callback)

  hget: (hash, key, callback) =>
    @client.hget hash, key, (err, result) =>
      return callback(err) if err
      result = @parse(result)
      value = result?.value
      if result?._redis_set_at
        now = moment().utc()
        if now.diff(result._redis_set_at) > @timeout
          @destroyHashKey hash, key, (err) => callback(err)
        else
          callback(null, value)
      else
        callback(null, value)

  set: (hash, key, value, callback) =>
    return @hset(hash, key, value, callback) if arguments.length is 4
    (callback = value; value = key; key = hash)
    if @timeout
      @client.psetex(key, @timeout, JSON.stringify(value), callback)
    else
      @client.set(key, JSON.stringify(value), callback)

  get: (hash, key, callback) =>
    return @hget(hash, key, callback) if arguments.length is 3
    (callback = key; key = hash)
    @client.get key, (err, result) =>
      return callback(err) if err
      callback(null, @parse(result))

  destroyHashKey: (hash, key, callback) =>
    @client.hdel(hash, key, callback)

  destroy: (key, callback) =>
    @client.del(key, callback)

  reset: (callback) -> @client.flushall callback

  # Parse an object whose values are still JSON stringified (for example, dates as strings in ISO8601 format).
  #
  # @example
  #   method: (req, res) ->
  #     query = @parse(req.query)
  #
  # Taken from backbone-orm
  #
  parse: (values) =>
    return null if _.isNull(values) or (values is 'null')
    return values if _.isDate(values)
    return _.map(values, @parse) if _.isArray(values)
    if _.isObject(values)
      result = {}
      result[key] = @parse(value) for key, value of values
      return result
    else if _.isString(values)
      try
        # Date
        if (values.length >= 20) and values[values.length-1] is 'Z'
          date = moment.utc(values)
          return if date and date.isValid() then date.toDate() else values
        # Stringified JSON
        return @parse(values) if values = JSON.parse(values)
      catch err
    return values
