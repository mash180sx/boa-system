Sync = require 'sync'

cluster = require 'cluster'
numWorkers = require('os').cpus().length

pc = require './lib/pricecheck'
conf = require './config'

db = require './lib/db'


# ////////// pricecheck search //////////
###
example = '9784876999767+%0D%0A9784839941239+%0D%0A9784401748693+%0D%0A9784120042201+%0D%0A9784860850999+%0D%0A9784776808121+%0D%0A9784046217585+%0D%0A9784336052117+%0D%0A9784490206937+%0D%0A9784829144916'
JANS = example.split '+%0D%0A'
console.log JANS
pc.getPCInfolist conf, JANS, (err, res)->
  console.log res
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
  
  unit = 10000
  
  Sync ->
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
    
    activeWorkers = numWorkers
    if cluster.isMaster # parent process
      # if worker is dead, fork another worker
      cluster.on 'death', (worker)->
        console.log "worker: #{worker.pid} is killed"
        activeWorkers--
        if activeWorkers is 0
          client.close()
      
      for i in [0...numWorkers]
        worker = cluster.fork()
      
        wkcb = do (i)->
          (msg)->
            if msg.cmd is 'ready'
              count = Commodities.count.sync Commodities, query
              if i*unit<count
                cursor = Commodities.find(query, field, \
                  {limit: unit, skip: i*unit})
                @send 
                  cmd: 'update'
                  parent: @pid
                  index: i*unit
                  cursor: cursor
              else
                @kill()
            return
                
        worker.on 'message', wkcb
    else
      process.on 'message', (msg)->
        if msg.cmd is 'update'
          parent = msg.parent
          index = msg.index
          cursor = msg.cursor
          until (doc = cursor.nextObject.sync(cursor)) is null
            console.log parent, index+1, doc
            JANS[index%unit] = doc.JAN
            if (++index%unit) is 0
              getter()
          if JANS.length > 0
            getter()
      
      process.send cmd: 'ready'
         