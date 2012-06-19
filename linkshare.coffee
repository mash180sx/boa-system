###
##  linkshare.coffee
##
##  TODO: 文字化け問題 : grep "�"
###
Sync = require 'sync'
zlib = require 'zlib'
fs = require 'fs'

{ftp} = require './lib/ftp'

conf = require './config'

db = require './lib/db'

{Stream, split, concate, dbinsert} = require './lib/stream'
#{split} = require './lib/stream'
#{concate} = require './lib/stream'
#{dbinsert} = require './lib/stream'

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
  _in = 0
  _out= 0
  
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
      switch MID
        when '25051'
          sku = data[0].slice 1
        else
          sku = data[0]
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
      _out++

    _in++
    return true
  
  stream.end = ->
    process.nextTick(->stream.emit 'end')
    console.log "makeJSON end: in=#{_in}, out=#{_out} : #{new Date}"

  return stream

###
## main : 
##
## TODO: ftp streamのBufferをUTF-8化できないか。。。
###

Category = []
category_id = []

# dbクリア
conf.db.clear = true
# ////////// DB open //////////
db.open conf.db, (err, client)->
  if err then throw err
  
  Categories = client.collection 'categories'
  Commodities = client.collection 'commodities'
    
  if conf.db.clear
    _Categories = ['本・雑誌', 'CD', 'DVD・ビデオ', 'ゲーム・おもちゃ']
    l = _Categories.length
    for hash, i in _Categories
      cb = do (i)->
        return (err, doc)->
          console.log doc[0]
          category_id[hash] = doc[0]._id
          Category[hash] = 0
          if i is l-1
            next()
      Categories.insert {name: hash}, {safe: true}, cb
  else
    next()
  
  next = ->
    console.log "next start: ", new Date
    seed = conf.seed
    txt = seed.replace '.gz',''

    # callback for ftp
    ftpcb = (err, stream) ->
      os = fs.createWriteStream txt
      stream.pipe(zlib.createGunzip()).pipe(os)
      stream.on 'success', fscb
    # callback for stream returned by ftp
    ds = dbinsert Commodities
    fscb = ->
      console.log 'fs success: ', new Date
      rs = fs.createReadStream txt, encoding: 'utf8'
      #os = process.stdout
      rs.pipe(split()).pipe(makeJSON()).pipe(concate()).pipe(ds)
      .on 'end', dscb
    # callback for dbinsert stream and close the db here
    dscb = ->
      console.log "ds start: ", new Date, ds.inputLength
      # wait to complete db insertion
      Sync ->
        loop
          console.log "insert: #{ds.outputLength}/#{ds.inputLength}"
          if ds.outputLength<ds.inputLength
            Sync.sleep 15*1000
          else
            client.close()
            return

    #ftp seed, conf.ftp, ftpcb
    fscb()
