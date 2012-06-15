mongodb = require 'mongodb'

module.exports = class DBModel extends mongodb
  constructor: (conf={
      name: 'test'
      host: 'localhost'
      port: 27017
  })->
    @conf = conf
    server = new mongodb.Server conf.host, conf.port, {}
    @client = new mongodb.Db conf.name, server, {}
  
  open: (conf=@conf, cb)->
    @client.open (err, client)->
      if err then return callback err
      Categories = client.collection 'categories'
      exports.Categories = Categories
      Commodities = client.collection 'commodities'
      exports.Commodities = Commodities
      if conf.clear
        Categories.drop()
        Commodities.drop()
        Commodities.ensureIndex 'MID'
        Commodities.ensureIndex 'sku'
        Commodities.ensureIndex 'JAN'
        Commodities.ensureIndex 'price.fixed'
        Commodities.ensureIndex 'price.new'
        Commodities.ensureIndex 'price.old'
        Commodities.ensureIndex 'price.buy'
        Commodities.ensureIndex 'amount'
        Commodities.ensureIndex 'isbn13'
        Commodities.ensureIndex 'isbn10'
        Commodities.ensureIndex 'pricecheck'
        Commodities.ensureIndex 'pricecheck.asin'
        Commodities.ensureIndex 'pricecheck.new'
        Commodities.ensureIndex 'pricecheck.old'
        Commodities.ensureIndex 'pricecheck.lank'
        Commodities.ensureIndex 'amazon'
        Commodities.ensureIndex 'amazon.asin'
        Commodities.ensureIndex 'amazon.new'
        Commodities.ensureIndex 'amazon.old'
        Commodities.ensureIndex 'amazon.rank'
      cb null, client
    