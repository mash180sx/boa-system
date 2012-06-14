mongodb = require 'mongodb'

server = new mongodb.Server 'localhost', 27017, {}
(new mongodb.Db 'test', server, {})
.open (err, client) ->
  if err then throw err
  
  Item = client.collection 'items'
  
  items = []
  for a in [1..1000]
    items[a-1] =
      name: 'a'+a
      code: a*3-2
  
  Item.insert items, {safe: true}, (err, docs) ->
    console.log docs
    client.close()
