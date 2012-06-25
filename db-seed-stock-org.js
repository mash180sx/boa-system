var Sync = require('sync');

var bookoff = require('./lib/bookoff');

var conf = require('./config');
console.log(conf);

var db = require('./lib/db');

Sync(function() {
  /*
  // ブック情報取得
  var sku = '0016433564'; // 謎解きはディナーのあとで
  var bookinfo = bookoff.getBOItemDetail.sync(null, sku, conf);
  console.log(bookinfo);
  */
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
