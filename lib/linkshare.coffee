/**
 * db-seed.js
 */
var Sync = require('sync');
var Future = Sync.Future;
var fs = require('fs');
var path = require('path');
var zlib = require('zlib');
var Ftp = require('ftp');
var es = require('event-stream');
var db = require('./lib/db');

var conf = require('./config');
console.log(conf);

var download = function(conf, callback) {
  if(conf.ftp.download===false) { return callback(null, filename); } 
  var host = (conf.ftp.firewall) ?
    conf.ftp.firewall : conf.ftp.host;
  var auth = (conf.ftp.firewall) ?
    conf.ftp.user+'@'+conf.ftp.host : conf.ftp.user;
  var pass = conf.ftp.pass;
  var filename = conf.seed;

  // new FTP client
  connect = new Ftp({ host : host });

  console.log('ftp.connect.start ' + host);
  // FTP connect
  connect.connect();
  // connect listener 'connect'
  connect.on('connect', function() {
    // authentication
    connect.auth(auth, pass, function(err) {
      if (err) {
        console.log('auth error');
        return callback(err);
      }

      // download filename
      connect.get(filename, function(err, stream) {
        if (err) {
          console.log('get error');
          return callback(err);
        }

        var os = fs.createWriteStream(filename);
        // stream listener 'success'
        stream.on('success', function() {
          console.log('download success : ' + filename);
          connect.end();
        })
        // stream listener 'error'
        .on('error', function(err) {
          console.log('ERROR during get(): ' + util.inspect(err));
          callback(err);
        })
        // stream pipeline (ftp->csv)
        .pipe(os)
        // stream.pipe(..).pipe(..) listener 'close'
        .on('close', function() {
          console.log('gz close' + filename);
          // this function callback(null, filename)
          callback(null, filename);
        });
      });
    });
  });
  // connect listener 'end'
  connect.on('end', function() {
    console.log('ftp.close');
    delete connect;
  });
}

var seed = conf.seed;
var txt = seed.replace('.gz','');

Sync(function(){
  // ftp download
  if(!(conf.ftp.download===false) || !path.existsSync(seed)) {
    conf.ftp.download = true;
    var filename = download.sync(null, conf);
    console.log('download %s complete!', filename);
    var os = fs.createWriteStream(txt);
    fs.createReadStream(seed).pipe(zlib.createGunzip()).pipe(os);
    console.log('gunzip %s complete!', txt);
  } else {
    console.log('download skip!');
    // ungzip
    if(!(conf.ftp.gzip===false) || !path.existsSync(txt)) {
      conf.ftp.gzip = true;
      var os = fs.createWriteStream(txt);
      fs.createReadStream(seed).pipe(zlib.createGunzip()).pipe(os);
      console.log('gunzip %s complete!', txt);
    } else {
      console.log('gunzip skip!');
    }
  }
  
  var Category = [];
  var nonCategory = 0;
  var category_id = [];
  
  // dbクリア
  conf.db.clear = true;
  ////////// DB open //////////
  db.open(conf.db, function(err, client) {
    if(err) throw err;
      
    var Categories = client.collection('categories');
    var Commodities = client.collection('commodities');
  
    if(conf.db.clear) {
      var _Categories = ['本・雑誌', 'CD', 'DVD・ビデオ', 'ゲーム・おもちゃ'];
      for(var i in _Categories) {
        var hash = _Categories[i];
        //console.log(hash);
        Categories.insert({name: hash}, {safe:true}, function(err, doc) {
          if(err) throw err;
          console.log(doc[0]);
          category_id[hash] = doc[0]._id;
          Category[hash] = 0;
        });
      }
    }
      
    ////////// event-stream : any stream pipe //////////
    var in1 = 0, in2 = 0;
    var out1 = 0, out2 = 0;
    var updateTime;
    var gate = es.gate();
    var MID;
    var esfs, esmap1, esmap2;
    var rest = '';
  
    es.connect(
      (esfs = fs.createReadStream(txt, {encoding: 'utf8'}))
      .on('data', function() {
        if((++in1%10)===0) esfs.pause();
      })
      .on('end', function() { console.log('esfs.end'); }),
      (esmap1 = es.map(function(_data, callback) {
        var dt = rest+_data;
        var lines = dt.split('\n');
        for(var i=0, l=lines.length-1; i<l; i++) {
          if((++in2%10)===0) gate.shut();
          callback(null, lines[i]);
        }
        rest = lines[i];
        if((++out1)===in1) esfs.resume();
      }))
      .on('end', function() { console.log('esmap1.end'); }),
      (esmap2 = es.map(function(item, callback) {
        var data = item.split('|');
        var _data;
        ////////// Header /////////////////////////////////
        if (data[0] === 'HDR') {
          MID = data[1];
          var name = data[2];
          updateTime = new Date(data[3]);
          // Merchandiser毎の個別処理
          name = name.replace('【PC・携帯共通】', '');
          _data = {
            MID : MID,
            name : name,
            update : updateTime
          };
          console.log('Header : %j', _data);
          callback(null, _data);
        ////////// Trailer ////////////////////////////////
        } else if (data[0] === 'TRL') {
          _data = data[1];
          console.log('Trailer %d', data[1]);
          console.log('index = %d', in2);
          console.log('None category = %d', nonCategory);
          // console.log('];');
          console.log('Seed_categories = ', Category, ';');
          // TODO: DB登録完了待ち合わせ
          Sync(function() {
            var total = in2 - nonCategory - 2;
            console.log('total insertion = %d (in1-nonCategory-2(head&tail))', total);
            console.log('complete insertion count = %d', out2);
            while(out2<total) {
              console.log('%d : %d (%3.1f)', out2, total, out2/total);
              Sync.sleep(15*1000);
            }
            db.close();
          });
          callback(null, _data);
        ////////// Body //////////////////////////////////
        } else {
          //console.log('body [%d] : %s', index2, item);
          var isbn13, isbn10;
          var keywords = data[18].split('~~');
          var prices = keywords[0].split('/');
          var fixed = (prices[2]&&prices[2].indexOf(':')>0) ?
              Number(prices[2].split(':')[1]): 0;
          var _new = (prices[1]&&prices[1].indexOf(':')>0) ?
              Number(prices[1].split(':')[1]): 0;
          var old = (prices[0]&&prices[0].indexOf(':')>0) ?
              Number(prices[0].split(':')[1]): 0;
          var buy = (prices[3]&&prices[3].indexOf(':')>0) ?
              Number(prices[3].split(':')[1]): 0;
          if (data[3] == '本・雑誌') {
            isbn13 = data[23];
            isbn10 = keywords[2];
          }
          var _type = ['', '中古', '新品', '大人買い'];
          var type = _type[data[0].charAt(0)];
          var sku = data[0].slice(1);
          var release = new Date(data[14]);
          _data = {
            title : data[1],
            category : {
              primary : data[3],
              sub : data[4].split('~~')
            },
            url: {
              item : data[5],
              image : data[6]
            },
            type : type,
            author : data[8],
            sku : sku,
            JAN : data[23],
            price : {
              fixed : fixed,
              new : _new,
              old : old,
              buy : buy
            },
            release : release,
            amount : 0,
            update : updateTime
          };
          // カテゴリ毎の個別処理
          switch (_data.category.primary) {
          case '本・雑誌':
            _data.isbn13 = isbn13;
            _data.isbn10 = isbn10;
            break;
          }
          var hash = _data.category.primary;
          if(hash) {
            if(hash in Category) {
              Category[hash]++;
            } else {
              Category[hash] = 1;
            }
            // _data.category_id = category_id[hash];
            Commodities.insert(_data, {safe:true}, function(err, doc) {
              if(err) throw err;
              if((++out2)===in2) {
                gate.open();
                //console.log('%d,%d,%d',index, index1, index2);
              }
              // console.log(doc);
              callback(null, _data);
            });
          } else {
            // console.log(' %j,', _data);
            nonCategory++;
          }
          // console.log('Body[%d] : %j', index, _data);
          // console.log(' %j,', _data);
        }
      }).on('end', function() {
         console.log('es.map end');
        // console.log('Category : ', Category);
      }))
    );  // es.connect
  });
  
});

