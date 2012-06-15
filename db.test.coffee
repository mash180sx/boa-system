Sync = require 'sync'
mongodb = require 'mongodb'

server = new mongodb.Server 'localhost', 27017, {}
db = new mongodb.Db 'test', server, {}
console.log "db: #{JSON.stringify db}"
Sync ->
  client = db.open.sync db
  
  Item = client.collection 'items'
  
  items = []
  for a in [1..10]
    items[a-1] =
      name: 'a'+a
      code: a*3-2
  
  Item.insert items, {safe: true}, (err, docs) ->
    console.log docs
    client.close()
