var Sync = require('sync');
var Future = Sync.Future;
var db = require('./lib/db');
var conf = require('./config');
var pc = require('./lib/pricecheck');

Sync(function() {
  //console.log(new Date());
  //Sync.sleep(2000);
  //console.log(new Date());
  
  /*
  var client = db.open.sync(null, conf.db);
  
  var collections = client.collectionNames.sync(client);
  console.log(collections);
  
  var Categories = client.collection.sync(client, 'categories');
  Categories.findOne(function(err, doc) {
    console.log(doc);
  })
  
  db.close();
  */
  var example = '9784876999767+%0D%0A9784839941239+%0D%0A9784401748693+%0D%0A9784120042201+%0D%0A9784860850999+%0D%0A9784776808121+%0D%0A9784046217585+%0D%0A9784336052117+%0D%0A9784490206937+%0D%0A9784829144916';
  var JANS = example.split('+%0D%0A');
  console.log(JANS);
  
  var res = pc.getPCInfolist.sync(null, conf, JANS);
  console.log(res);


  var client = db.open.sync(null, conf.db);
  
  Sync.sleep(60*1000);
  db.close();
});