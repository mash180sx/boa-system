var Sync = require('sync');
var Future = Sync.Future;
var db = require('./lib/db');
var conf = require('./config');
var pc = require('./lib/pricecheck');
var db = require('./lib/db');

Sync(function() {
  ////////// DB open //////////
  var client = db.open.sync(null, conf.db);

  var Commodities = client.collection('commodities');
  
  Commodities.update({pricecheck:{$exists:1}}, {$unset:{pricecheck:1}}, {multi:true});
  Sync.sleep(15*1000);
  ////////// pricecheck search //////////
  //var example = '9784876999767+%0D%0A9784839941239+%0D%0A9784401748693+%0D%0A9784120042201+%0D%0A9784860850999+%0D%0A9784776808121+%0D%0A9784046217585+%0D%0A9784336052117+%0D%0A9784490206937+%0D%0A9784829144916';
  //var JANS = example.split('+%0D%0A');
  //console.log(JANS);
  //var res = pc.getPCInfolist.sync(null, conf, JANS);
  //console.log(res);
  
  var updater = function(JANS, pcDoc, callback) {
    var count = 0;
    for(var i=0, l=JANS.length; i<l; i++) {
      //console.log(JANS[i], pcDoc[i]);
      Commodities.update({JAN: JANS[i]}, {$set: {pricecheck: pcDoc[i]}});
      count++;
    }
    callback(null, count);
  }
  var in1=0, out1=0, JANS = [];
  // commoditiesのうち、在庫のあるもの(amount=1)についてPriceCheckを実施
  var stream = Commodities.find({amount:1, JAN:{$ne:''}}, {JAN:1,amount:1}).stream();
  stream.on('data', function(doc) {
    if(doc) {
      in1++;
      stream.pause();
      Sync(function() {
        JANS[0] = doc.JAN;
        res = pc.getPCInfolist.sync(null, conf, JANS);
        //console.log(res);
        updater(JANS, res, function(err, count) {
          delete JANS;
          JANS = [];
          out1 += 1;
          console.log(in1, out1);
          if(in1===out1) stream.resume();
        });
      });
    }
/*
      JANS[(in1%10)] = doc.JAN;
      //console.log(in1, doc);
    } else {
      if(JANS && JANS.length>0) {
        res = pc.getPCInfolist.sync(null, conf, JANS);
        console.log('end', res);
        out1 += JANS.length;
        console.log(in1, out1);
      }
    }
    //console.log(in1,' : ',doc);
    if((++in1%10)===0) {
      stream.pause();
      Sync(function() {
        res = pc.getPCInfolist.sync(null, conf, JANS);
        //console.log(res);
        updater(JANS, res, function(err, count) {
          delete JANS;
          JANS = [];
          out1 += 10;
          console.log(in1, out1);
          if(in1===out1) stream.resume();
        });
      })
    }
*/
  });
  
  ////////// DB close //////////
  console.log('search result = %d', in1);
  //db.close();
});