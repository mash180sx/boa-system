var mongodb = require('mongodb');
exports.mongodb = mongodb;

var db = null;

exports.open = function(conf, callback) {
  var server = new mongodb.Server(conf.host, conf.port, {});
  (db = new mongodb.Db(conf.name, server, {}))
  .open(function(err, client) {
    if(err) return callback(err);
    
    var Categories = client.collection('categories');
    exports.Categories = Categories;
    var Commodities = client.collection('commodities');
    exports.Commodities = Commodities;
    var Temp = client.collection('temp');
    exports.Temp = Temp;
    var Manage = client.collection('manage');
    exports.Manage = Manage;
    if(conf.clear) {
      Categories.drop();
      Commodities.drop();
    }
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
    Commodities.ensureIndex('pricecheck.JAN');
    Commodities.ensureIndex('pricecheck.asin');
    Commodities.ensureIndex('pricecheck.new');
    Commodities.ensureIndex('pricecheck.old');
    Commodities.ensureIndex('pricecheck.lank');
    Commodities.ensureIndex('amazon');
    Commodities.ensureIndex('amazon.JAN');
    Commodities.ensureIndex('amazon.asin');
    Commodities.ensureIndex('amazon.new');
    Commodities.ensureIndex('amazon.old');
    Commodities.ensureIndex('amazon.rank');
    Temp.ensureIndex('JAN');
    Temp.ensureIndex('sku');
    Temp.ensureIndex('asin');
    Temp.ensureIndex('cat');
    Temp.ensureIndex('pold');
    Temp.ensureIndex('pnew');
    Temp.ensureIndex('aold');
    Temp.ensureIndex('anew');
    Temp.ensureIndex('gross_profit');
    Temp.ensureIndex('gross_profit_ratio');
    Temp.ensureIndex('amount');
    Temp.ensureIndex('operation_count');
    Manage.ensureIndex('JAN');
    Manage.ensureIndex('sku');
    Manage.ensureIndex('asin');
    Manage.ensureIndex('cat');
    Manage.ensureIndex('pold');
    Manage.ensureIndex('pnew');
    Manage.ensureIndex('aold');
    Manage.ensureIndex('anew');
    Manage.ensureIndex('gross_profit');
    Manage.ensureIndex('gross_profit_ratio');
    Manage.ensureIndex('amount');
    Manage.ensureIndex('operation_count');
    callback(null, client);
  });
};

exports.close = function() {
  db.close();
  db = null;
}