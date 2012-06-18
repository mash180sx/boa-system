Sync = require 'sync'

cluster = require 'cluster'
numWorkers = require('os').cpus().length

conf = require './config'
pc = require './lib/pricecheck'
db = require './lib/db'

httpGet = require './lib/httpGet'

if process.argv.length>=3
  skip = Number process.argv[2]
  console.log "skip: #{skip}"
else skip = 0

###
## main:
###
db.open conf.db, (err, client)->
  if err then throw err

  Commodities = client.collection 'commodities'
  
  key = 'JAN'
  query = {}
  query[key] = $ne: '' # JAN: {$ne: ''}, amazon: {$exists: false}
  query.amazon = $exists: false
  field = _id: 0
  field[key] = 1 # JAN:1, _id:0
  options = {sort: key}
  if skip>0 then options.skip = skip
  #console.log query, field
  cursor = Commodities.find query, field, options
  Sync ->
    index = 0 + skip
    unit = 10
    JANS = []
    updater = (data)->
      for d, i in data
        #console.log JSON.stringify d
        query[key] = d.JAN
        update = {$set: {amazon: d}}
        options = {safe: true}
        #console.log 'update: ', JSON.stringify(query), JSON.stringify(update), JSON.stringify(options)
        Sync ->
          doc = Commodities.update.sync Commodities, query, update, options
    getter = ->
      data = pc.getList.sync null, conf.http, JANS
      # data is not valid if not same JANS.length and data.length
      if JANS.length is data.length
        updater data
        # test results are valid
        # use getDetail
        #for d, i in data
        #  res = pc.getDetail.sync null, conf.http, d.asin
        #  console.log "#{d.JAN} = #{res.JAN} -> #{d.JAN is res.JAN}"
        # TEST OK!!!
      else
        console.log "data contains valid data"
        for JAN,i in JANS
          data = pc.getList.sync null, conf.http, [JAN]
          if data.length>0 
            updater data
          else
            updater [{JAN: JAN, asin: null}]
      JANS = []
    until (doc = cursor.nextObject.sync(cursor)) is null
      console.log index+1, doc
      JANS[index%unit] = doc.JAN
      if (++index%unit) is 0
        getter()
    if JANS.length > 0
      getter()
    client.close()
        