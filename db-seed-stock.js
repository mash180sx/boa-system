// Generated by CoffeeScript 1.3.3
(function() {
  var bo, conf, db, limit, no_new_rate, no_used_rate, out_collection, total_size;

  conf = require('./config');

  db = require('./lib/db');

  bo = require('./lib/bookoff');

  no_used_rate = 0.8;

  no_new_rate = 10.0;

  out_collection = "temp";

  limit = 10000;

  total_size = 20000;

  db.open(conf.db, function(err, client) {
    var Temp, options, query, update;
    if (err) {
      throw err;
    }
    Temp = client.collection('temp');
    console.log('Temp amount initialize start');
    query = {
      amount: 1
    };
    update = {
      $set: {
        amount: 0
      }
    };
    options = {
      safe: true,
      multi: true
    };
    Temp.update(query, update, options, function(err, count) {
      console.log('update count', count);
      return console.log('Temp amount initialize done');
    });
    return bo.getBOGenreList(conf, function(err, genreList) {
      var deleted, func, l, maxpage, page, total_stock, total_update, _i, _results;
      maxpage = conf.bookoff.depth != null ? conf.bookoff.depth : 1000 * 1000;
      deleted = 0;
      total_stock = 0;
      total_update = 0;
      _results = [];
      for (page = _i = 0; 0 <= maxpage ? _i <= maxpage : _i >= maxpage; page = 0 <= maxpage ? ++_i : --_i) {
        console.log('page :   %d / %d', page, maxpage);
        l = genreList.length;
        func = function(i) {
          var genre, retry, stock;
          if (i === l) {
            return;
          }
          genre = genreList[i];
          stock = null;
          retry = function(err) {
            console.log("Error: " + err);
            return setTimeout(function() {
              return func(i);
            }, 15 * 1000);
          };
          return bo.getBOStockList(conf, genre.id, page + 1, function(err, stock) {
            var list, pnew, pold, _j, _len, _ref, _ref1;
            if (err) {
              return retry(err);
            }
            query = {
              sku: list.sku
            };
            update = {
              $set: {
                amount: 1
              }
            };
            if ((pold = typeof list !== "undefined" && list !== null ? (_ref = list.price) != null ? _ref.old : void 0 : void 0) >= 0) {
              update.pold = pold;
            }
            if ((pnew = typeof list !== "undefined" && list !== null ? list.price["new"] : void 0) >= 0) {
              update.pnew = pnew;
            }
            options = {
              safe: true
            };
            _ref1 = stock.list;
            for (_j = 0, _len = _ref1.length; _j < _len; _j++) {
              list = _ref1[_j];
              Temp.update(query, update, options, function(err, count) {
                if (err) {
                  return retry(err);
                }
                return total_update++;
              });
              total_stock += list.length;
            }
            if (stock.total <= (page + 1) * 20) {
              delete genreList[i];
              console.log('genre[%d] deleted!', genre.id);
              deleted++;
              if (deleted === l) {
                console.log('search completed!');
                client.close();
                process.exit();
              }
            }
            return process.nextTick(func(i + 1));
          });
        };
        _results.push(func(0));
      }
      return _results;
    });
  });

  /*
  var Sync = require('sync');
  
  var bookoff = require('./lib/bookoff');
  
  var conf = require('./config');
  console.log(conf);
  
  var db = require('./lib/db');
  
  Sync(function() {
    // ブック情報取得
    var sku = '0016433564'; // 謎解きはディナーのあとで
    var bookinfo = bookoff.getBOItemDetail.sync(null, sku, conf);
    console.log(bookinfo);
    ////////// DB open //////////
    var client = db.open.sync(null, conf.db);
  
    var Commodities = client.collection('commodities');
    
    // 在庫のクリア
    console.log('Commodities amount initialize start');
    Commodities.update({amount:1}, {$set: {amount:0}}, {safe:true, multi:true},
       function(err, count) {
      console.log('update count', count);
      console.log('Commodities amount initialize done');
    });
    Sync.sleep(5*1000);
    console.log('sleep end');
    
    ////////// bookoff search //////////
    // ジャンル一覧の取得：各ジャンルのトップURLがわかる(各ジャンルの件数まではわからない)
    var genreList = bookoff.getBOGenreList.sync(null, conf);
    //console.log(genreList);
    
    // 各ジャンルデータ取得
    var maxpage = (conf.bookoff.depth) ? conf.bookoff.depth : 1000*1000;
    var deleted = 0;
    var total_stock = 0;
    var total_update = 0;
    // depth指定によるループ
    for(var page = 0; page<maxpage; page++) {
      console.log('page :   %d / %d', page, maxpage);
      // 全ジャンルについて実施
      for(var i=0, l=genreList.length; i<l; i++) {
        var genre = genreList[i];
        if(genre) {
          var stock = null;
          // ブックオフから中古情報を20件ずつ取得(リトライ10回)
          for(var retry=0; retry<10; retry++) {
            try {
              stock = bookoff.getBOStockList.sync(null, conf, genre.id, page+1);
              break;
            } catch(err) {
              console.log('Error retry %d times (delay time 15s) ', retry, err);
              Sync.sleep(15*1000);
              stock = null;
            }
          }
          //console.log('%d : ',genre.id, stock);
          ///// update commodities stock /////
          var list = stock.list;
          //console.log('stocklist = ', list);
          if(list) {
            for(var j=0, jl=list.length; j<jl; j++) {
              Commodities.update(list[j], { $set: { amount : 1 }}, {safe:true},
                  function(err, count) {
                if(err) throw err;
                total_update++;
              });
            }
            total_stock += list.length;
          }
  
          // 全データ取得したらそのジャンルを配列から削除
          if(stock.total<=(page+1)*20) {
            delete genreList[i];
            console.log('genre[%d] deleted!', genre.id);
            deleted++;
            if(deleted==l) {
              console.log('search completed!');
              maxpage = 0;
            }
          }
        }
      }
    }
    
    ////////// DB close //////////
    console.log('total stock     = %d', total_stock);
    console.log('complete update = %d', total_update);
    // TODO: DB登録完了待ち合わせ
    while(total_update<total_stock) {
      console.log('%d : %d (%3.1f)', total_update, total_stock, total_update/total_stock);
      Sync.sleep(15*1000);
    }
    db.close();
  });
  */


}).call(this);
