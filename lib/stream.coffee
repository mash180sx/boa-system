
###
##  stream.coffee : pipable stream skelton
##
##  TODO: pause, resume or another unsupported
##        (to be referring the 'event-stream')
##
##  TODO: referctor all streams to class description
##
###
{Stream} = require 'stream'

exports.Stream = Stream

exports.stream = () ->
  stream = new Stream
  
  stream.writable = true
  stream.readable = true
  
  stream.write = (buffer) ->
    # TODO: here you put code to process chunk data
    #       buffer is chunk data from pipe stream
    
    # necessary you can emit 
    data = buffer
    stream.emit 'data', buffer
    return true
  
  stream.end = ->
    # TODO: here you put code ending process

    stream.emit 'end'

  return stream

###
## split : line split stream
###
exports.split = (matcher) ->
  stream = new Stream
  soFar = ''  
  
  if not(matcher) then matcher = '\n'

  stream.writable = true
  stream.readable = true
  
  _in = 0
  _out = 0
  
  stream.write = (buffer) ->
    pieces = (soFar + buffer).split(matcher)
    soFar = pieces.pop()

    pieces.forEach (piece) ->
      stream.emit 'data', piece
      _out++

    _in++;
    return true
  
  stream.end = ->
    if soFar
      stream.emit 'data', soFar
      _out++
    process.nextTick(->stream.emit 'end')
    console.log "split end: in=#{_in}, out=#{_out} : #{new Date}"

  return stream

###
##  concate stream : concate stream
##
##  concate chunk data to array
###
exports.concate = (unit=100) ->
  stream = new Stream
  
  stream.writable = true
  stream.readable = true
  
  index = 0
  data = []
  _in = 0
  _out = 0
  
  stream.write = (buffer) ->
    data[index%unit] = buffer
    if (++index % unit) is 0
      stream.emit 'data', data
      data = []
      _out++
    
    _in++
    return true
  
  stream.end = ->
    if (index % unit) > 0
      stream.emit 'data', data
      data = []
      _out++

    process.nextTick(->stream.emit 'end')
    console.log "concate end: in=#{_in}, out=#{_out} : #{new Date}"

  return stream

### TODO: should move db.coffee(unmake) these streams below !!! ###
###
##  db insert stream : pipable stream skelton
##  
##  insert records to db
###
exports.dbinsert = (collection, options={}) ->
  options ||= {safe: true}
  stream = new Stream
  
  stream.writable = true
  stream.readable = true
  
  stream.inputLength = 0
  stream.outputLength = 0
  
  stream.write = (buffer) ->
    stream.inputLength++
    collection.insert buffer, options, (err, doc)->
      stream.outputLength++
      return true
  
  stream.end = ->
    stream.writable = stream.readable = false
    process.nextTick(->stream.emit 'end')
    console.log "dbinsert end: in=#{stream.inputLength}, out=#{stream.outputLength} : #{new Date}"

  return stream

###
##  db update stream : pipable stream skelton
##  
##  update record to db
###
exports.dbupdate = (collection, options={}, keys=['_id']) ->
  options.safe = true
  #console.log "options: #{JSON.stringify options}"
  #console.log "keys: #{keys}"
  
  stream = new Stream
  
  stream.writable = true
  stream.readable = true
  
  stream.inputLength = 0
  stream.outputLength = 0
  
  stream.write = (buffer) ->
    stream.inputLength++
    key = {}
    key[k] = buffer[k] for k in keys
    buffer.number = stream.inputLength # for debug
    update = {$set: buffer}
    #console.log key, update
    collection.update key, update, options, (err, doc)->
      stream.outputLength++
      return true
  
  stream.end = ->
    stream.writable = stream.readable = false
    process.nextTick(->stream.emit 'end')
    console.log "dbupdate end: in=#{stream.inputLength}, out=#{stream.outputLength} : #{new Date}"

  return stream

###
##  db find stream : pipable stream skelton
##  
##  db find
###
exports.dbfind = (collection, query={}, field={}, options={}) ->
  #console.log "options: #{JSON.stringify options}"
  #console.log "keys: #{keys}"
  
  stream = collection.find(query, field).stream()
  #stream = new Stream
  
  stream.writable = true
  stream.readable = true
  
  stream.inputLength = 0
  stream.outputLength = 0
  
  stream.on 'close', ->
    stream.emit 'end'
  
  return stream
###
exports.dbfind = (collection, query={}, field={}, options={}) ->
  #console.log "options: #{JSON.stringify options}"
  #console.log "keys: #{keys}"
  
  stream = new Stream
  
  stream.writable = true
  stream.readable = true
  
  stream.inputLength = 0
  stream.outputLength = 0
  
  stream.cursor = collection.find(query, field)
  stream.cursor.each (err, doc)->
    if err
      stream.emit 'error', err

    if doc
      stream.inputLength++
      #console.log doc
      process.nextTick ->
        #stream.emit 'data', "#{JSON.stringify doc}\n"
        stream.emit 'data', doc
        stream.outputLength++
    else
      #console.log "doc is null"
      stream.emit 'end'
      console.log "dbfind end: in=#{stream.inputLength}, out=#{stream.outputLength} : #{new Date}"

  return stream
###
