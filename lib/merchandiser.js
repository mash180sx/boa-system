var fs = require('fs');
var ftp = require('ftp');
var zlib = require('zlib');
var es = require('event-stream');
var stream = require('stream');
var util = require('util');
var async = require('async');
var db = require('../lib/db');

var MONGO_URL = process.env.MONGOHQ_URL || 'localhost/delivery_system';
if (process.env.NODE_ENV === 'test') {
  MONGO_URL = 'localhost/delivery_system-test';
}

// FTPを使用してMerchadiserサーバから、MIDのCSVデータを取得
// input  : param = {
//            [firewall: firewall,]
//            host: host,
//            user: user,
//            pass: pass,
//            MID: MID,
//            siteID: siteID,
//            [ftp: true,]
//            [initDb: true,]
//            [limit: Number,]
//          }
//          MID,siteIDは必須。ftpを使用しない場合はfalseを指定。DBを初期化しない場合falseを指定
// output : callback(err, csv)　 err = Error, csv = CSVファイル名
exports.importData = function(param, callback) {
  console.log('import start');
  console.log('time stamp = '+new Date());
  // paramの初期設定
  if(!param.MID || !param.siteID || !param.host || !param.user || !param.pass) 
    return callback(new Error('param not enough: Please define check param'));
  if(param.ftp!==false) { param.ftp=true;}
  if(param.initDB!==false) { param.initDB=true;}

  // FTP全般の定数定義
  var firewall = param.firewall;
  var host = param.host;
  var user = param.user;
  var pass = param.pass;
  console.log('firewall '+firewall);

  // Merchandiserに関する定義
  // ファイル名 : MMMMM_2870306_mp.txt.gz　MMMMMはMID
  var MID = param.MID;
  var siteID = param.siteID;
  var filename = MID + "_" + siteID + "_mp.txt.gz"

  // ftp connectとmongoDB connectを並列に実行
  async.parallel([
  // ftpサーバにconnectしてconnectを返す
  function(callback) {
    // FTP接続初期化
    var connect='', auth='';
    
    if(!param.ftp) { return callback(null, connect); }

    if(firewall) {
      console.log('connect '+firewall);
      connect = new ftp({ host: firewall });
      auth = user + '@' + host;
    } else {
      console.log('connect '+host);
      connect = new ftp({ host: host });
      auth = user;
    }

    // 接続処理(イベント処理)
    connect.on('connect', function() {
      // 認証
      connect.auth(auth, pass, function(err) {
        if(err) return callback(err);
        callback(null, connect);
      });
    })
    .on('error', function(err) {
      if(err) callback(err);
    })
    .on('timeout', function() {
      callback(new Error('Ftp connect : session timeout'));
    })
    // 接続処理開始
    connect.connect();
  },
  // mongoDB接続初期化
  function(callback) {
    console.log('db.connect.start');
    setTimeout(function() {
      db.connect(MONGO_URL, function(err) {
        if (err) return callback(err);
        console.log('db.connect.done');
        Merchandiser = db.Merchandiser;
        Item = db.Item;
        Stock = db.Stock;

        //param.initDBがtrueならMerchandiser(MID)とitem(MID)を初期化
        //TODO:初期化の待ち合わせ必要
        if(param.initDB) {
          async.parallel([
          function(callback) {
            Merchandiser.remove({MID: MID}, function(err, count) {
              if(err) return callback(err);
              console.log('Merchandiser.remove.count = %d', count);
              callback(null, count);
            });
          },
          function(callback) {
            Item.remove({MID: MID}, function(err, count) {
              if(err) return callback(err);
              console.log('Item.remove.count = %d', count);
              callback(null, count);
            });
          }],
          function(err, results) {
            if(err) return callback(err);
            console.log(results);
            callback(null, db);
          });
        }
      });
    }, 100);
  },
  ],
  // ftp,mongoDBの接続後の処理(メイン処理)
  function(err, results) {
    //console.log('results : '+results);
    var connect = results[0];
    //console.log(ftpStream);
    var db = results[1];
    //console.log(db);
    async.waterfall([
    function(callback) {
      console.log('set csv');
      var ftpStream;
      var download= filename;
      var csv = filename.replace('.gz','');
      if(param.ftp) {
        // ftpStream取得
        connect.get(download, function(err, ftpStream) {
          if(err) return callback(err);

          var out = fs.createWriteStream(csv);
          ftpStream.pipe(zlib.createGunzip()).pipe(out)
          .on('close',function() {
            console.log('csv close');
            callback(null, csv);
          });
          ftpStream.on('success', function() {
            console.log('download success : '+download);
            connect.end();
          });
          ftpStream.on('error', function(err) {
            return callback(err);
          });
        });
      } else {
        callback(null, csv);
      }
    },
    function(csv, callback) {
      var index = 0;
      var updateTime;
      var gate = es.gate();
      var index1 = 0, index2 = 0;
      var esfs, esmap;
      console.log('event-stream.start');
      es.connect(
        (esfs = fs.createReadStream(csv, { encoding: 'utf8' })),
        es.split()
        .on('data', function(data) {
          if((++index1%10)==0) { gate.shut(); }
          if(index1>param.limit) { esfs.destroy(); };
        }),
        esmap = es.map(function(data, callback) {
          //console.log(data);
          index2++;
          var data = data.split('|');
          var _data;
          if(data[0]==='HDR') {
            console.log('header');
            var name = data[2];
            updateTime = new Date(data[3]);
            // Merchandiser毎の個別処理
            switch(MID) {
            case '25051':
              name = name.replace('【PC・携帯共通】','');
              break;
            case '2431':
            case '36805':
              break;
            }
            var _data = {
              MID: MID,
              name: name,
              update: updateTime
            };
            Merchandiser.insert(_data, function(err, doc) {
              if(err) return callback(err);
              //callback(null, doc);
            });
          } else if(data[0]==='TRL') {
            _data = data[1];
            console.log('Trailer %d', data[1]);
            //callback(null, data[1]);
          } else {
            //console.log('body [%d]', index);
            // Merchandiser毎の個別処理
            switch(MID) {
            case '25051':
              if(data[3]=='本・雑誌') {
                keywords = data[18].split('~~');
                isbn13 = data[23];
                isbn10 = keywords[2];
              }
              sku = data[0].slice(1);
              break;
            default:
              sku = data[0];
            }
            var sale = new Date(data[14]);
            _data = {
              title: data[1],
              category: {
                primary: data[3],
                secondary: data[4]
              },
              author: data[8],
              MID: [MID],
              sku: [sku],
              JAN: data[23],
              price: data[13],
              sale: sale,
              update: updateTime
            };

            // カテゴリ毎の個別処理
            switch(_data.category.primary) {
            case '本・雑誌':
              _data.isbn13 = isbn13;
              _data.isbn10 = isbn10;
              break;
            }
            Item.insert(_data, function(err, doc) {
              if(err) return callback(err);
              //callback(null, doc);
              if((index2%10)==0) { gate.open();};
              if(param.limit && index2>param.limit) { esmap.end(); };
            });
          }
          callback(null, _data);
        })
        .on('end', function() {
          console.log('es.map end');
          callback(null, 'event-stream ok');
        })
      )
    },
    ],
    function(err, result) {
      // 終了処理
      // DBを切断
      console.log('db.close.start');
      db.close(function(err) {
        if(err) {
          return callback(err);
        } else {
          console.log('result '+result);
          console.log('db.close.done');
          console.log('time stamp = '+new Date());
          callback(null, 'all done');
        }
      });
    });
  });
}

