Sync = require 'sync'
{Stream, concate, dbfind, dbupdate} = require './lib/stream'

conf = require './config'
pc = require './lib/pricecheck'
db = require './lib/db'

if process.argv.length>=3
  skip = Number process.argv[2]
  console.log "skip: #{skip}"
else skip = 0

###
##  stream : pipable stream
##
##  TODO: pause, resume or another unsupported
##        (to be referring the 'event-stream')
###
pcstream = (unit=1000)->
  stream = new Stream
  stream.name = "pcstream"
  
  stream.writable = true
  stream.readable = true
  stream.inputLength = 0
  stream.outputLength = 0
  stream.unit = unit
  
  stream.write = (buffer) ->
    #console.log "#{@name}: #{JSON.stringify buffer}\n"
    stream.inputLength++
    pc.getPCInfolist conf, [buffer.JAN], (err, data)->
      if err
        stream.emit 'error', err
        console.log "#{@name}: error = #{err}"
        return
      if data[0]?
        #console.log "#{stream.name}: data = #{JSON.stringify data[0]}"
        stream.emit 'data', data[0]
        stream.outputLength++
        if (q = stream.inputLength-stream.outputLength) >= stream.unit
          console.log "#{@name}: queue full"
          return false
        else if q is 0
          console.log "#{@name}: drain"
          stream.emit 'drain'
          return true
      else
        console.log "#{@name}: JAN not found"
        return true
  
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
  query.amazon = $exists: false
  field = _id: 0
  field[key] = 1 # JAN:1, _id:0
  options = sort: key
  if skip>0 then options.skip = skip
  #console.log query, field
  Commodities = client.collection 'commodities'

  ds = dbfind Commodities, query, field
  pcs = pcstream()
  dus = dbupdate Commodities, {}, [key]
  ds.on 'data', (data)->
    if pcs.write(data) is false
      ds.pause()
  pcs.on 'drain', ->
    ds.resume()

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
