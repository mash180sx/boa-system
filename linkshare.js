// Generated by CoffeeScript 1.3.1

/*
##  linkshare.coffee
##
##  TODO: 文字化け問題 : grep "�"
*/


(function() {
  var Category, Stream, Sync, category_id, concate, conf, db, dbinsert, fs, ftp, inputLength, makeJSON, outputLength, split, zlib;

  Sync = require('sync');

  Stream = require('stream').Stream;

  zlib = require('zlib');

  fs = require('fs');

  ftp = require('./lib/ftp').ftp;

  conf = require('./config');

  db = require('./lib/db');

  /*
  ## split : line split stream
  */


  split = function(matcher) {
    var soFar, stream, _in, _out;
    stream = new Stream;
    soFar = '';
    if (!matcher) {
      matcher = '\n';
    }
    stream.writable = true;
    stream.readable = true;
    _in = 0;
    _out = 0;
    stream.write = function(buffer) {
      var pieces;
      pieces = (soFar + buffer).split(matcher);
      soFar = pieces.pop();
      pieces.forEach(function(piece) {
        stream.emit('data', piece);
        return _out++;
      });
      _in++;
      return true;
    };
    stream.end = function() {
      if (soFar) {
        stream.emit('data', soFar);
        _out++;
      }
      process.nextTick(function() {
        return stream.emit('end');
      });
      return console.log("split end: in=" + _in + ", out=" + _out + " : " + (new Date));
    };
    return stream;
  };

  /*
  ## makeJSON : make JSON stream
  */


  makeJSON = function() {
    var MID, index, name, stream, updateTime, _in, _out, _type;
    stream = new Stream;
    stream.writable = true;
    stream.readable = true;
    _type = ['', '中古', '新品', '大人買い'];
    MID = null;
    name = null;
    updateTime = null;
    index = 0;
    _in = 0;
    _out = 0;
    stream.write = function(buffer) {
      var buy, data, fixed, isbn10, isbn13, keywords, old, prices, release, sku, type, _data, _new, _ref, _ref1, _ref2, _ref3;
      data = buffer.split('|');
      if (data[0] === 'HDR') {
        MID = data[1];
        name = data[2].replace('【PC・携帯共通】', '');
        updateTime = new Date(data[3]);
        _data = {
          MID: MID,
          name: name,
          update: updateTime
        };
      } else if (data[0] === 'TRL') {
        _data = data[1];
        /*
              console.log('Trailer %d', data[1]);
              console.log('index = %d', in2);
              console.log('None category = %d', nonCategory);
              # console.log('];');
              console.log('Seed_categories = ', Category, ';');
        */

        stream.end();
      } else {
        keywords = data[18].split('~~');
        prices = keywords[0].split('/');
        fixed = ((_ref = prices[2]) != null ? _ref.indexOf(':') : void 0) > 0 ? Number(prices[2].split(':')[1]) : 0;
        _new = ((_ref1 = prices[1]) != null ? _ref1.indexOf(':') : void 0) > 0 ? Number(prices[1].split(':')[1]) : 0;
        old = ((_ref2 = prices[0]) != null ? _ref2.indexOf(':') : void 0) > 0 ? Number(prices[0].split(':')[1]) : 0;
        buy = ((_ref3 = prices[3]) != null ? _ref3.indexOf(':') : void 0) > 0 ? Number(prices[3].split(':')[1]) : 0;
        if (data[3] === '本・雑誌') {
          isbn13 = data[23];
          isbn10 = keywords[2];
        }
        type = _type[data[0].charAt(0)];
        sku = data[0].slice(1);
        release = new Date(data[14]);
        _data = {
          title: data[1],
          category: {
            primary: data[3],
            sub: data[4].split('~~')
          },
          url: {
            item: data[5],
            image: data[6]
          },
          type: type,
          author: data[8],
          sku: sku,
          JAN: data[23],
          price: {
            fixed: fixed,
            "new": _new,
            old: old,
            buy: buy
          },
          release: release,
          mount: 0,
          update: updateTime
        };
        switch (_data.category.primary) {
          case '本・雑誌':
            _data.isbn13 = isbn13;
            _data.isbn10 = isbn10;
        }
        stream.emit('data', _data);
        _out++;
      }
      _in++;
      return true;
    };
    stream.end = function() {
      process.nextTick(function() {
        return stream.emit('end');
      });
      return console.log("makeJSON end: in=" + _in + ", out=" + _out + " : " + (new Date));
    };
    return stream;
  };

  /*
  ##  concate stream : concate stream
  ##
  ##  concate chunk data to array
  */


  concate = function(unit) {
    var data, index, stream, _in, _out;
    if (unit == null) {
      unit = 100;
    }
    stream = new Stream;
    stream.writable = true;
    stream.readable = true;
    index = 0;
    data = [];
    _in = 0;
    _out = 0;
    stream.write = function(buffer) {
      data[index % unit] = buffer;
      if ((++index % unit) === 0) {
        stream.emit('data', data);
        data = [];
        _out++;
      }
      _in++;
      return true;
    };
    stream.end = function() {
      if ((index % unit) > 0) {
        stream.emit('data', data);
        data = [];
        _out++;
      }
      process.nextTick(function() {
        return stream.emit('end');
      });
      return console.log("concate end: in=" + _in + ", out=" + _out + " : " + (new Date));
    };
    return stream;
  };

  /*
  ##  db insert stream : pipable stream skelton
  ##  
  ##  insert array to db
  */


  inputLength = 0;

  outputLength = 0;

  dbinsert = function(collection) {
    var index, stream, _in, _out;
    stream = new Stream;
    stream.writable = true;
    stream.readable = true;
    index = 0;
    _in = 0;
    _out = 0;
    stream.write = function(buffer) {
      inputLength++;
      return collection.insert(buffer, {
        safe: true
      }, function(err, doc) {
        _in++;
        outputLength++;
        return true;
      });
    };
    stream.end = function() {
      stream.writable = stream.readable = false;
      process.nextTick(function() {
        return stream.emit('end');
      });
      return console.log("dbinsert end: in=" + _in + ", out=" + _out + " : " + (new Date));
    };
    return stream;
  };

  /*
  ## main : 
  ##
  ## TODO: ftp streamのバッファをUTF-8化できないか。。。
  */


  Category = [];

  category_id = [];

  conf.db.clear = true;

  db.open(conf.db, function(err, client) {
    var Categories, Commodities, cb, hash, i, l, next, _Categories, _i, _len;
    if (err) {
      throw err;
    }
    Categories = client.collection('categories');
    Commodities = client.collection('commodities');
    if (conf.db.clear) {
      _Categories = ['本・雑誌', 'CD', 'DVD・ビデオ', 'ゲーム・おもちゃ'];
      l = _Categories.length;
      for (i = _i = 0, _len = _Categories.length; _i < _len; i = ++_i) {
        hash = _Categories[i];
        cb = (function(i) {
          return function(err, doc) {
            console.log(doc[0]);
            category_id[hash] = doc[0]._id;
            Category[hash] = 0;
            if (i === l - 1) {
              return next();
            }
          };
        })(i);
        Categories.insert({
          name: hash
        }, {
          safe: true
        }, cb);
      }
    } else {
      next();
    }
    return next = function() {
      var dscb, fscb, ftpcb, seed, txt;
      console.log("next start: ", new Date);
      seed = conf.seed;
      txt = seed.replace('.gz', '');
      ftpcb = function(err, stream) {
        var os;
        os = fs.createWriteStream(txt);
        stream.pipe(zlib.createGunzip()).pipe(os);
        return stream.on('success', fscb);
      };
      fscb = function() {
        var rs;
        console.log('fs success: ', new Date);
        rs = fs.createReadStream(txt, {
          encoding: 'utf8'
        });
        return rs.pipe(split()).pipe(makeJSON()).pipe(concate()).pipe(dbinsert(Commodities)).on('end', dscb);
      };
      dscb = function() {
        console.log("ds start: ", new Date, inputLength);
        return Sync(function() {
          while (true) {
            console.log("insert: " + outputLength + "/" + inputLength);
            if (outputLength < inputLength) {
              Sync.sleep(15 * 1000);
            } else {
              client.close();
              return;
            }
          }
        });
      };
      return ftp(seed, conf.ftp, ftpcb);
    };
  });

}).call(this);
