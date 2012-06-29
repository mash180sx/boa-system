conf = require './config'
db = require './lib/db'

###
 * TODO: 前回のCommoditiesがあれば、そのJANをハッシュに保存する
###
 
db.open conf.db, (err, client)->
  if err then throw err
  
  Commodities = client.collection 'commodities'
  
  # 前回データをハッシュに保存
  query = {JAN:{$ne:''}}
  fields = {JAN:1, _id:0}
  options = {sort: 'JAN'}
  index = 0
  Commodities.count query, (err, count)->
    if err then throw err
    console.log "total_size = #{count}"
    
  Commodities.find(query, fields, options).each (err, doc)->
    console.log ++index, doc