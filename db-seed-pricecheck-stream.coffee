Sync = require 'sync'
{Stream, concate, dbfind, dbupdate} = require './lib/stream'

conf = require './config'
pc = require './lib/pricecheck'
db = require './lib/db'


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
    pc.getPCInfolist conf, [buffer.JAN], (err, data)->
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

  ds = dbfind Commodities, query, field
  pcs = pcstream()
  dus = dbupdate Commodities, {}, [key]

  # callback for dbinsert stream and close the db here
  duscb = ->
    console.log "dus start: ", new Date, ds.inputLength
    # wait to complete db insertion
    Sync ->
      loop
        console.log "update: #{ds.outputLength}/#{ds.inputLength}"
        if ds.outputLength<ds.inputLength
          Sync.sleep 15*1000
        else
          client.close()
          return
  
  ds.pipe(pcs).pipe(dus).on 'end', duscb
