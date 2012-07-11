conf = require './config'
# db = require './lib/db'
bo = require './lib/bookoff'

getBOGenreList = (cb, retry=0)->
  name = "getBOGenreList"
  setTimeout ->
    bo.getBOGenreList conf, (err, result)->
      if err is null then return cb null, result
      console.log "Error: #{err}"
      setTimeout ->
        console.log "#{name}: retry=#{++retry}"
        getBOGenreList cb, retry
      , 15 * 1000
  , 200
  return

getBOStockList = (id, page, cb, retry=0)->
  name = "getBOStockList"
  setTimeout ->
    bo.getBOStockList conf, id, page, (err, result)->
      if err is null then return cb null, result
      console.log "Error: #{err}"
      setTimeout ->
        console.log "#{name}: retry=#{++retry}"
        getBOStockList id, page, cb, retry
      , 15 * 1000
  , 200
  return

db.open conf.db, (err, client)->
  if err then throw err

  Commodities = client.collection 'commodities'
  Temp = client.collection 'temp'
  
  getBOGenreList (err, genres)->
    if err then return console.log "Error: #{err}"
    console.log "genres:", genres
    
    len = genres.length
    console.log "len: #{len}"
    
    maxpage = if (depth=conf.bookoff.depth)>0 then depth else 1000*1000
    total_count = 0
    map = (i)->
      console.log "map #{i} / #{len}"
      if i is len
        console.log "end"
        process.exit()
      if (genre = genres[i])
        #console.log "genres[#{i}] ok"
        genre = genres[i]
        #console.log "genre.id = #{genre.id}"
        genre_total = 0
        map2 = (page, retry=0)->
          console.log "map2 #{genre.id}, #{page}"
          getBOStockList genre.id, page, (err, stocks)->
            if err then console.log "Error: #{err}"
            #else console.log stocks
            genre_total = if (st=stocks?.total)>0 then st else genre_total
            if not(st>0) and ++retry<10
              console.log "search no = 0, retry = #{retry}"
              return process.nextTick (-> map2 page, retry)
            console.log "page*20: #{page*20}, total: #{genre_total} page: #{page}, maxpage: #{maxpage}"
            for stock, i in stocks
              doc.amount = amount = detail.amount
              doc.pold = pold = detail.price.old
              doc.pnew = pnew = detail.price['new']
              console.log index++, skip+i, JSON.stringify(doc)
              query2 = sku:doc.sku
              update = $set: doc
              options2 = safe: true, upsert: true
              # Commodities update async
              Commodities.update query2, $set: 
                amount: amount
                "price.old": pold
                "price.new": pnew
              # Temp update async
              func = do ->
                Temp.update query2, update, options2, (err, count)->
                  if err
                    console.log "Error: #{err} and retry"
                    setTimeout (->func()), 100
                    return
            if page*20 < genre_total and page < maxpage
              process.nextTick (-> map2(page+1))
            else
              process.nextTick (-> map(i+1))
        map2 1
      else
        console.log "deleted"
        process.nextTick (-> map(i+1))
    map 0
