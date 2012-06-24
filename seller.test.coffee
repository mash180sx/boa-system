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

  Tests = client.collection 'tests'
  
  Tests.insert
    a: 1
    b: 3
    c: new BSON.Code 'this.a + this.b'
  , (err, doc)->
    client.close()