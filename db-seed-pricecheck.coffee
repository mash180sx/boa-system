Sync = require 'sync'
{Stream, concate, dbfind, dbupdate} = require './lib/stream'

conf = require './config'
pc = require './lib/pricecheck'
db = require './lib/db'

httpGet = require './lib/httpGet'

###
##  stream : pipable stream
##
##  TODO: pause, resume or another unsupported
##        (to be referring the 'event-stream')
###
pcstream = ->
  stream = new Stream
  stream.name = "pcstream"
  
  stream.writable = true
  stream.readable = true
  stream.inputLength = 0
  stream.outputLength = 0
  
  stream.write = (buffer) ->
    #console.log "#{@name}: #{JSON.stringify buffer}\n"
    stream.inputLength++
    pc.getList conf.http, [buffer.JAN], (err, data)->
      if err
        stream.emit 'error', err
        console.log "#{@name}: error = #{err}"
        return
      if data[0]?
        process.nextTick ->
          console.log "#{stream.name}: data = #{JSON.stringify data[0]}"
          stream.emit 'data', data[0]
          stream.outputLength++
          return true
      else
        console.log "#{@name}: JAN not found"
  
  stream.end = ->
    stream.emit 'end'
    console.log "#{@name} end: in=#{@inputLength}, out=#{@outputLength} : #{new Date}"
  
  return stream


###
## main:
###
db.open conf.db, (err, client)->
  if err then throw err

  key = 'JAN'
  query = {}
  query[key] = $ne: '' # JAN: {$ne: ''}
  field = _id: 0
  field[key] = 1 # JAN:1, _id:0
  #console.log query, field
  Commodities = client.collection 'commodities'

  cursor = Commodities.find(query, field)
  Sync ->
    index = 0
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
        