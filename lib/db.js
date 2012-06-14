var mongodb = require('mongodb');

var db = null;

exports.open = function(conf, callback) {
  var server = new mongodb.Server(conf.host, conf.port, {});
  exports.server = server;
  (exports.mongodb = new mongodb.Db(conf.name, server, {}))
  .open(function(err, client) {
    if(err) return callback(err);
    
    exports.client = db = client;
    var Categories = client.collection('categories');
    exports.Categories = Categories;
    var Commodities = client.collection('commodities');
    exports.Commodities = Commodities;
    if(conf.clear) {
      Categories.drop();
      Commodities.drop();
      Commodities.ensureIndex('MID');
      Commodities.ensureIndex('sku');
      Commodities.ensureIndex('JAN');
      Commodities.ensureIndex('price.fixed');
      Commodities.ensureIndex('price.new');
      Commodities.ensureIndex('price.old');
      Commodities.ensureIndex('price.buy');
      Commodities.ensureIndex('amount');
      Commodities.ensureIndex('isbn13');
      Commodities.ensureIndex('isbn10');
      Commodities.ensureIndex('pricecheck');
      Commodities.ensureIndex('pricecheck.asin');
      Commodities.ensureIndex('pricecheck.new');
      Commodities.ensureIndex('pricecheck.old');
      Commodities.ensureIndex('pricecheck.lank');
      Commodities.ensureIndex('amazon');
      Commodities.ensureIndex('amazon.asin');
      Commodities.ensureIndex('amazon.new');
      Commodities.ensureIndex('amazon.old');
      Commodities.ensureIndex('amazon.rank');
    }
    callback(null, client);
  });
};

exports.close = function() {
  db.close();
  db = null;
}