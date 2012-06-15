###
##  linkshare.coffee
##
##  TODO: 文字化け問題 : grep "�"
###
{Stream} = require 'stream'
zlib = require 'zlib'
fs = require 'fs'

{ftp} = require './lib/ftp'

conf = require './config'

db = require './lib/db'

###
## split : line split stream
###
split = (matcher) ->
  stream = new Stream
  soFar = ''  
  
  if not(matcher) then matcher = '\n'

  stream.writable = true
  stream.readable = true
  stream.write = (buffer) ->
    pieces = (soFar + buffer).split(matcher)
    soFar = pieces.pop()

    pieces.forEach (piece) ->
      stream.emit 'data', "#{piece}"

    return true
  
  stream.end = ->
    if soFar
      stream.emit 'data', "#{soFar}"
    stream.emit 'end'

  return stream


###
## makeJSON : make JSON stream
###
makeJSON = ->
  stream = new Stream
  
  stream.writable = true
  stream.readable = true
  
  _type = ['', '中古', '新品', '大人買い']
  MID = null
  name = null
  updateTime = null
  index = 0
  stream.write = (buffer) ->
    data = buffer.split '|'
    # ////////// Header ////////////////////////////////////////
    if data[0] is 'HDR'
      MID = data[1]
      name = data[2].replace '【PC・携帯共通】', ''
      updateTime = new Date(data[3])
      # Merchandiser毎の個別処理
      _data = 
        MID : MID
        name : name
        update : updateTime
      #console.log "Header : #{JSON.stringify _data}"
    # ////////// Trailer ////////////////////////////////////////
    else if data[0] is 'TRL'
      _data = data[1];
      ###
      console.log('Trailer %d', data[1]);
      console.log('index = %d', in2);
      console.log('None category = %d', nonCategory);
      # console.log('];');
      console.log('Seed_categories = ', Category, ';');
      ###
      stream.end()
    else
      #console.log('body [%d] : %s', index2, item);
      #if ++index>10 then process.exit()
      keywords = data[18].split '~~'
      prices = keywords[0].split '/'
      fixed = if prices[2]?.indexOf(':')>0 then Number(prices[2].split(':')[1]) else 0
      _new = if prices[1]?.indexOf(':')>0 then Number(prices[1].split(':')[1]) else 0
      old = if prices[0]?.indexOf(':')>0 then Number(prices[0].split(':')[1]) else 0
      buy = if prices[3]?.indexOf(':')>0 then Number(prices[3].split(':')[1]) else 0
      if data[3] is '本・雑誌'
        isbn13 = data[23]
        isbn10 = keywords[2]
      type = _type[data[0].charAt(0)]
      sku = data[0].slice 1
      release = new Date(data[14])
      _data = 
        title: data[1]
        category:
          primary: data[3]
          sub: data[4].split '~~'
        url:
          item: data[5]
          image: data[6]
        type: type
        author: data[8]
        sku: sku
        JAN: data[23]
        price:
          fixed: fixed
          new: _new
          old: old
          buy: buy
        # release : {"$date": Number(release)} # for mongoimport
        release : release
        mount : 0
        # update : {"$date": Number(updateTime)} # for mongimport
        update : updateTime
      # カテゴリ毎の個別処理
      switch _data.category.primary
        when '本・雑誌'
          _data.isbn13 = isbn13;
          _data.isbn10 = isbn10;
    
      stream.emit 'data', _data

    return true
  
  stream.end = ->
    stream.emit 'end'

  return stream


###
##  concate stream : concate stream
##
##  concate chunk data to array
###
concate = (unit=100) ->
  stream = new Stream
  
  stream.writable = true
  stream.readable = true
  
  index = 0
  data = []
  
  stream.write = (buffer) ->
    data[index] = buffer
    if (++index % unit) is 0
      stream.emit 'data', data
      data = []
    
    return true
  
  stream.end = ->
    if (index % unit) > 0
      stream.emit 'data', data
      data = []

    stream.emit 'end'

  return stream

###
##  db insert stream : pipable stream skelton
##  
##  insert array to db
###
dbinsert = () ->
  stream = new Stream
  
  stream.writable = false
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
## main : 
###
seed = conf.seed

#ftp seed, conf.ftp, (err, stream) ->
txt = seed.replace '.gz',''
#  os = fs.createWriteStream txt
#  (zs = stream.pipe(zlib.createGunzip())).pipe(os)
#  zs.on 'end', ->
#rs = fs.createReadStream txt, encoding: 'utf8'
#os = process.stdout
#rs.pipe(split()).pipe(makeJSON()).pipe(os)

Category = []
category_id = []

# dbクリア
conf.db.clear = true
# ////////// DB open //////////
db.open conf.db, (err, client)->
  if err then throw err
  
  close = (done=->)->
    done()
    client.close()

  Categories = client.collection 'categories'
  Commodities = client.collection 'commodities'
    
  if conf.db.clear
    _Categories = ['本・雑誌', 'CD', 'DVD・ビデオ', 'ゲーム・おもちゃ']
    count = 0
    dones = [].map.call _Categories, (el)-> (-> console.log ++count)
    console.log dones
    for hash, i in _Categories
      cb = do (i)->
        return (err, doc)->
          console.log doc[0]
          category_id[hash] = doc[0]._id
          Category[hash] = 0
          dones[i]()
      Categories.insert {name: hash}, {safe: true}, cb
  else
    close()
  