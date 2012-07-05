conf = require './config'
# db = require './lib/db'
bo = require './lib/bookoff'

getBOGenreList = (cb)->
  @name = "getBOGenreList"
  @retry = 0
  setTimeout ->
    bo.getBOGenreList conf, (err, result)->
      if err is null then return cb null, result
      console.log "Error: #{err}"
  , 200
  setTimeout =>
    console.log "#{@name}: retry=#{++@retry}"
    process.nextTick -> getBOGenreList cb
  , 15 * 1000

getBOStockList = (id, page, cb)->
  @name = "getBOStockList"
  @retry = 0
  setTimeout ->
    bo.getBOStockList conf, id, page, (err, result)->
      if err is null then return cb null, result
      console.log "Error: #{err}"
  , 200
  setTimeout =>
    console.log "#{@name}: retry=#{++@retry}"
    process.nextTick -> getBOStockList id, page, cb
  , 15 * 1000

getBOGenreList (err, genres)->
  if err then return console.log "Error: #{err}"
  console.log "test:", genres
  
  for genre in genres
    getBOStockList genre.id, 1, (err, stocks)->
      if err then console.log "Error: #{err}"
      console.log stocks