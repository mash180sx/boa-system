conf = require './config'
db = require './lib/db'

# TODO: to insert db following parameters
no_used_rate = 0.8
no_new_rate = 10.0
out_collection = "temp"
limit = 1000
total_size = 1000

db.open conf.db, (err, client)->
  if err then throw err

  Commodities = client.collection 'commodities'
  
  query = { $or: [
    {"amazon.old":{$gt:1000}}
    {"amazon.old":0, "amazon.new":0}
    {"amazon.old":0, "amazon.new":{$gt:1000}}]}
  #fields = {_id:0, JAN:1, "amazon.asin":1, "price.old":1, "price.new":1, "amazon.old":1, "amazon.new":1}
  #options = {sort: "price.old"}
  index = 0
  
  map = ->
    result = 
      pold: @.price.old
      pnew: @.price["new"]
      cat: @.category.primary
      asin: @.amazon.asin
      aold: @.amazon.old
      anew: @.amazon["new"]
    
    result.sales_price = sales_price =
      if (aold=@.amazon.old)>0
        if aold>(anew=@.amazon["new"])>0
          result.type = 1
          parseInt anew * no_used_rate
        else
          result.type = 2
          aold
      else if (anew=@.amazon.new)>0
        result.type = 3
        parseInt anew * no_used_rate
      else
        result.type = 4
        parseInt price.new * no_new_rate
    # TODO: total_cost : append delivery cost, commission, etc.
    result.net_price = net_price = @.price.old
    result.delivery_cost = delivery_cost = if net_price>1500 then 0 else 350
    result.total_cost = total_cost = net_price + delivery_cost

    result.gross_profit = gross_profit = sales_price - total_cost
    
    result.gross_profit_ratio = gross_profit_ratio = gross_profit / sales_price
    
    emit @JAN, result
    return
  
  reduce = (key, values)->
    if values.length>1
      console.log "values.length: #{values.length}"
    values[0]
  
  scope = no_used_rate: no_used_rate, no_new_rate: no_new_rate
  
  options = 
    out: {merge: out_collection}
    query: query
    scope: scope
  if limit>0 then options.limit = limit
  
  ###
  mapReduce = (i, skip)->
    console.log "do mapReduce(#{i}, #{skip})"
    if skip>0 then options.skip = skip
    Commodities.mapReduce map, reduce, options, (err, collection)->
      if err then throw err
      query2 = {} #gross_profit: {$gt: 1000}
      options2 = sort: [["value.gross_profit", -1]]
      collection.find(query2, {}, options2).each (err, doc)->
        if err then throw err
        console.log index++, JSON.stringify(doc)
        if doc is null
          if skip is total_size
            client.close()
            process.exit()
          else
            mapReduce i+1, skip+limit
  
  mapReduce 0, 0
  ###
  
  Commodities.mapReduce map, reduce, options, (err, collection)->
    if err then throw err
    query2 = {} #gross_profit: {$gt: 1000}
    options2 = sort: [["value.gross_profit", -1], ["value.gross_profit_ratio", 1]]
    collection.find(query2, {}, options2).each (err, doc)->
      if err then throw err
      console.log index++, JSON.stringify(doc)
      if doc is null
        client.close()
        process.exit()

  ###
  cursor = collection.find()
  loop
    cursor.nextObject (err, doc)->
      if err then throw err
      console.log index++, JSON.stringify(doc)
      if doc is null
        client.close()
        process.exit()
  ###
