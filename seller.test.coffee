conf = require './config'
db = require './lib/db'
BSON = db.mongodb.BSONPure


# TODO: to insert db following parameters
no_used_rate = 0.8
no_new_rate = 10.0
out_collection = "temp"
limit = 1000
total_size = 1000

db.open conf.db, (err, client)->
  if err then throw err

  Temp = client.collection 'temp'
  
  query = {}
  fields = {}
  options = sort: [["value.gross_profit", -1], ["value.gross_profit_ratio", 1]]
  if limit>0 then options.limit = limit
  index = 0
  Temp.find(query, fields, options).each (err, doc)->
    if err then throw err
    console.log index++, JSON.stringify(doc)
    if doc is null
      client.close()
      process.exit()
