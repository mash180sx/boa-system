conf = require './config'
db = require './lib/db'


db.open conf.db, (err, client)->
  if err then throw err

  Commodities = client.collection 'commodities'
  
  query = { $or: [{"amazon.old":{$gt:1000}}, {"amazon.old":0, "amazon.new":0}]}
  fields = {_id:0, JAN:1, "amazon.asin":1, "price.old":1, "price.new":1, "amazon.old":1, "amazon.new":1}
  options = {sort: "price.old"}
  index = 0
  Commodities.find(query, fields, options).each (err, doc)->
    if err then throw err
    console.log index++, JSON.stringify(doc)
    if index is 100
      client.close()
      process.exit()
      