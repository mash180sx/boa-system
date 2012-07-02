conf = require './config'
db = require './lib/db'
pc = require './lib/pricecheck'

#if process.argv.length>=3
#  skip = Number process.argv[2]
#else skip = 0
#console.log "skip: #{skip}"

limit = 10
total_size = 20000

db.open conf.db, (err, client)->
  if err then throw err

  Commodities = client.collection 'commodities'
  #Temp.update {amount:1}, {$set:{amount:0}}, {multi:true}

  query = {JAN:{$ne:''}}
  fields = {_id:0, JAN:1}
  options = sort: [["JAN", 1]] #, ["gross_profit_ratio", 1]]
  if limit>0 then options.limit = limit
  index = 0
  cursor = Commodities.find query, fields, options
  map = (skip)->
    console.log "skip: #{skip}/total_size: #{total_size}"
    if skip is total_size
      client.close()
      process.exit()
    if skip>0 then options.skip = skip
    Commodities.find(query, fields, options).toArray (err, docs)->
      if err
        console.log "Error: #{err} and retry"
        setTimeout (->map i), 15*1000
        return
      len = docs.length
      map2 = ->
        JANS = []
        for doc, i in docs
          console.log JANS[i] = doc.JAN
        pc.getList conf.http, JANS, (err, datas)->
          if err
            console.log "Error: #{err} and retry"
            setTimeout (->map2()), 15*1000
            return
          #console.log "#{index+1}..#{index+len}: #{JANS}"
          index+=len
          return process.nextTick (-> map(skip+limit))
          if datas.length is len
            for data, i in datas
              q = {JAN: data.JAN}
              update = {$set: {amazon: data}}
              options = {safe: true}
              func = ->
                Commodities.update q, update, options, (err, count)->
                  if err
                    console.log "Error: #{err} and retry"
                    process.nextTick (-> func())
                    return
                  if (i+1) is len
                    index+=len
                    return process.nextTick (-> map(skip+limit))
              func()
          else
            console.log "data contains valid data : JANS #{len} - datas #{datas.length}"
            map3 0
      map3 = (i)->
        if i is len
          return process.nextTick(-> map(skip+limit))
        JAN = docs[i].JAN
        pc.getList conf.http, [JAN], (err, datas)->
          if err
            console.log "Error: #{err} and retry"
            setTimeout (->map3 i), 15*1000
            return
          if datas.length>0
            data = datas[0]
          else
            data = {JAN: JAN, asin: null}
          q = {JAN: JAN}
          update = {$set: {amazon: data}}
          options = {safe: true}
          func = ->
            Commodities.update q, update, options, (err, count)->
              if err
                console.log "Error: #{err} and retry"
                process.nextTick (-> func())
                return
              console.log "#{++index}: #{JAN}"
              if (i+1) is len
                process.nextTick (-> map3(i+1))
                return
              else
                map3(i+1)
          func()
      map2()
  
  console.log "Commodities.count"
  cursor.count (err, count)->
    total_size = Math.ceil(count/limit) * limit
    console.log "total_size = #{total_size}"
    map 0

