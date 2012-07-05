conf = require './config'
# db = require './lib/db'
bo = require './lib/bookoff'

bo.getBOGenreList conf, (err, genres)->
  if err then console.log "Error: #{err}"
  #console.log "test:", genres
  
  for genre in genres
    bo.getBOStockList conf, genre.id, 1, (err, stocks)->
      console.log stocks