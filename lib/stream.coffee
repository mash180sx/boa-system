###
##  stream.coffee : pipable stream skelton
##
##  TODO: pause, resume or another unsupported
##        (to be referring the 'event-stream')
###
stream = (matcher) ->
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
