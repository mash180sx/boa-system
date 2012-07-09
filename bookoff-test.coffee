conf = require './config'
# db = require './lib/db'
bo = require './lib/bookoff'

getBOGenreList = (cb)->
  name = "getBOGenreList"
  retry = 0
  setTimeout ->
    bo.getBOGenreList conf, (err, result)->
      if err is null then return cb null, result
      console.log "Error: #{err}"
      setTimeout ->
        console.log "#{name}: retry=#{++retry}"
        getBOGenreList cb
      , 15 * 1000
  , 200
  return

getBOStockList = (id, page, cb)->
  name = "getBOStockList"
  retry = 0
  setTimeout ->
    bo.getBOStockList conf, id, page, (err, result)->
      if err is null then return cb null, result
      console.log "Error: #{err}"
      setTimeout ->
        console.log "#{name}: retry=#{++retry}"
        getBOStockList id, page, cb
      , 15 * 1000
  , 0
  return

getBOGenreList (err, genres)->
  if err then return console.log "Error: #{err}"
  console.log "genres:", genres
  
  len = genres.length
  console.log "len: #{len}"
  
  map = (i)->
    console.log "map #{i} / #{len}"
    if i is len
      console.log "end"
      process.exit()
    if (genre = genres[i])
      #console.log "genres[#{i}] ok"
      genre = genres[i]
      #console.log "genre.id = #{genre.id}"
      total = if (depth=conf.bookoff.depth)>0 then depth*20 else 1000*1000
      count = 0
      map2 = (page)->
        console.log "map2 #{genre.id}, #{page} : #{count}/#{total}"
        getBOStockList genre.id, page, (err, stocks)->
          total = stocks.total
          if err then console.log "Error: #{err}"
          #else console.log stocks
          count += stocks?.list?.length
          console.log "count: #{count}, total: #{total}"
          if count < total
            process.nextTick (-> map2(page+1))
          else
            process.nextTick (-> map(i+1))
      map2 1
    else
      console.log "deleted"
      process.nextTick (-> map(i+1))
  map 0