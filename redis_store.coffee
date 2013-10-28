UrlUtils = require 'url'
redis = require 'redis'
_ = require 'underscore'

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

  set: (key, value, callback) =>
    if @timeout
      @client.psetex(key, @timeout, JSON.stringify(value), callback)
    else
      @client.set(key, JSON.stringify(value), callback)

  get: (key, callback) =>
    @client.get key, (err, result) =>
      return callback(err) if err
      callback(null, @parse(result))

  destroy: (key, callback) =>
    @client.del(key, callback)

  reset: (callback) -> @client.flushall callback

  # Parse an object whose values are still JSON stringified (for example, dates as strings in ISO8601 format).
  #
  # @example
  #   method: (req, res) ->
  #     query = JSONUtils.parse(req.query)
  #
  # Taken from backbone-orm
  #
  parse: (values) ->
    return null if _.isNull(values) or (values is 'null')
    return values if _.isDate(values)
    return _.map(values, JSONUtils.parse) if _.isArray(values)
    if _.isObject(values)
      result = {}
      result[key] = JSONUtils.parse(value) for key, value of values
      return result
    else if _.isString(values)
      # Date
      if (values.length >= 20) and values[values.length-1] is 'Z'
        date = moment.utc(values)
        return if date and date.isValid() then date.toDate() else values

      # Boolean
      return true if values is 'true'
      return false if values is 'false'

      return match[0] if match = /^\"(.*)\"$/.exec(values) # "quoted string"

      # stringified JSON
      try
        return JSONUtils.parse(values) if values = JSON.parse(values)
      catch err
    return values
