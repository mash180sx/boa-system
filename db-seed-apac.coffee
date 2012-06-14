Sync = require 'sync'

apac = require './lib/apac'
db = require './lib/db'

conf = require './config'

Sync ->
  # ////////// DB open //////////
  client = db.open.sync null, conf.db

  Commodities = client.collection('commodities')
  
  Commodities.update {amazon:{$exists:1}}, {$unset:{amazon:1}}, {multi:true}
  Sync.sleep 15*1000 
  
  updater = (items, callback) ->
    for item, i in items
      console.log item
      #Commodities.update {JAN: item.JAN}, {$set: {amazon: item}}
    callback null, i

  in1=0
  out1=0
  JANS = []
  # commoditiesのうち、在庫のあるもの(amount=1)について Apacを実施
  #stream = Commodities.find({amount:1, JAN:{$ne:''}}, {JAN:1,amount:1}).stream()
  stream = Commodities.find({JAN:{$ne:''}}, {JAN:1,amount:1}).stream()
  stream.on 'data', (doc) ->
    if doc?
      console.log(in1, doc);
      JANS[(in1%10)] = doc.JAN;
      if (++in1%10) is 0
        stream.pause();
        Sync ->
          res = apac.getApaclist.sync null, conf.amazon, JANS
          # console.log(res);
          updater JANS, res, (err, count) ->
            JANS = [];
            out1 += 10;
            console.log in1, out1
            if in1 is out1 then stream.resume()
            return
    else
      if JANS?.length > 0
        Sync ->
          res = apac.getApaclist.sync null, conf.amazon, JANS
          console.log 'end', res
          out1 += JANS.length;
          console.log in1, out1
          
          Sync.sleep 15*1000
          # ////////// DB close //////////
          console.log "search result = #{in1}"
          db.close()
