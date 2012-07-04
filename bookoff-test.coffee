conf = require './config'
# db = require './lib/db'
bo = require './lib/bookoff'

bo.getBOGenreList conf, (err, genre)->
  console.log "test:", genre
  