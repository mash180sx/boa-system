conf = require './config'
db = require './lib/db'
bo = require './lib/bookoff'

if process.argv.length>=3
  skip = Number process.argv[2]
  console.log "skip: #{skip}"
else skip = 0

# TODO: to insert db following parameters
no_used_rate = 0.8
no_new_rate = 10.0
out_collection = "temp"
limit = 10000
total_size = 20000

db.open conf.db, (err, client)->
  if err then throw err

  Commodities = client.collection 'commodities'
  Temp = client.collection 'temp'
  Manage = client.collection 'manage'
  #Temp.update {amount:1}, {$set:{amount:0}}, {multi:true}

  query = {gross_profit:{$gte:1000}}
  fields = {_id:0}
  options = sort: [["gross_profit", -1]] #, ["gross_profit_ratio", 1]]
  if limit>0 then options.limit = limit
  index = 0
  map = (skip)->
    index = skip
    console.log "skip: #{skip}/total_size: #{total_size}"
    if skip is total_size
      client.close()
      process.exit()
    if skip>0 then options.skip = skip
    Temp.find(query, fields, options).toArray (err, docs)->
      if err
        console.log "Error: #{err} and retry"
        setTimeout (->map skip), 15*1000
        return
      len = docs.length
      map2 = (i)->
        if i is len
          index--
          process.nextTick(-> map(skip+limit))
          return
        doc = docs[i]
        if doc.sku?
          setTimeout ->
            bo.getBOItemDetail doc.sku, conf, (err, detail)->
              if err
                console.log "Error: #{err} and retry"
                setTimeout (->map2 i), 15*1000
                return
              if detail.amount?
                doc.amount = amount = detail.amount
                doc.pold = pold = detail.price.old
                doc.pnew = pnew = detail.price['new']
                console.log index++, JSON.stringify(doc)
                query2 = sku:doc.sku
                update = $set: doc
                options2 = safe: true, upsert: true
                # Commodities update async
                Commodities.update query2, $set: 
                  amount: amount
                  "price.old": pold
                  "price.new": pnew
                # Temp update async
                func = ->
                  Temp.update query2, update, options2, (err, count)->
                    if err
                      console.log "Error: #{err} and retry"
                      setTimeout (->func()), 100
                      return
                func()
                map2(i+1)
              else
                console.log index++, detail
                map2(i+1)
          , 200   # TODO: to consern the bookoff wab access delay -> now 200 msec
      map2 0
  
  Temp.count query, (err, count)->
    total_size = Math.ceil(count/limit) * limit
    map skip

