conf = require './config'
db = require './lib/db'

###
 * TODO: 前回のCommoditiesがあれば、そのJANをハッシュに保存する
###
dbclose = (client)->
  console.log "db close()"
  client.close()
  
db.open conf.db, (err, client)->
  if err then throw err
  
  Commodities = client.collection 'commodities'
  
  # 前回データをハッシュに保存
  query = JAN:{$ne:''}
  fields = JAN:1, _id:0
  options = sort: {JAN: 1}
  index = 0
  len = 1000*1000
  Commodities.count query, (err, count)->
    if err then throw err
    console.log "total_size = #{count}"
    len = count
    
  cursor = Commodities.find query, fields, options
  cursor.rewind()
  hash = []
  makeHash = ->
    cursor.nextObject (err, doc)->
      #console.log "#{++index}/#{len}: ", doc
      unless doc then return dbclose client
      hash[doc.JAN] = true
      process.nextTick -> makeHash()
  makeHash()

