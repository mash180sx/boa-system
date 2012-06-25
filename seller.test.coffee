conf = require './config'
db = require './lib/db'
bo = require './lib/bookoff'


# TODO: to insert db following parameters
no_used_rate = 0.8
no_new_rate = 10.0
out_collection = "temp"
limit = 10000
total_size = 20000

db.open conf.db, (err, client)->
  if err then throw err

  Temp = client.collection 'temp'

  query = {gross_profit:{$gte:1000}}
  fields = {_id:0}
  options = sort: [["gross_profit", -1]] #, ["gross_profit_ratio", 1]]
  if limit>0 then options.limit = limit
  index = 0
  map = (skip)->
    console.log "skip: #{skip}/total_size: #{total_size}"
    if skip is total_size
      client.close()
      process.exit()
    if skip>0 then options.skip = skip
    i = 0
    bofinal = ->
      if i is 0 
        --index
        process.nextTick (-> map(skip+limit))
    Temp.find(query, fields, options).toArray (err, docs)->
      if err then throw err
      l = docs.length
      func = (i)->
        if i is l then return
        doc = docs[i]
        bocb = (err, detail)->
          if err
            console.log "#{doc.sku}  Error: #{err}"
            setTimeout ->
              func i
            , 15*1000
            return
          else if detail?.amount?
            doc.amount = detail.amount
            #console.log index++, JSON.stringify(doc)
            console.log index++, doc.sku, doc.gross_profit, doc.gross_profit_ratio, doc.amount
            Temp.update {sku:doc.sku}, {$set:{amount:doc.amount}}
          else
            console.log index++, detail
          func(i+1)
        bo.getBOItemDetail doc.sku, conf, bocb
      func 0
  
  Temp.count query, (err, count)->
    total_size = Math.ceil(count/limit) * limit
    map 0

