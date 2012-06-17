// Generated by CoffeeScript 1.3.1
(function() {
  var Stream, Sync, concate, conf, db, dbfind, dbupdate, httpGet, pc, pcstream, _ref;

  Sync = require('sync');

  _ref = require('./lib/stream'), Stream = _ref.Stream, concate = _ref.concate, dbfind = _ref.dbfind, dbupdate = _ref.dbupdate;

  conf = require('./config');

  pc = require('./lib/pricecheck');

  db = require('./lib/db');

  httpGet = require('./lib/httpGet');

  /*
  ##  stream : pipable stream
  ##
  ##  TODO: pause, resume or another unsupported
  ##        (to be referring the 'event-stream')
  */


  pcstream = function() {
    var stream;
    stream = new Stream;
    stream.name = "pcstream";
    stream.writable = true;
    stream.readable = true;
    stream.inputLength = 0;
    stream.outputLength = 0;
    stream.write = function(buffer) {
      stream.inputLength++;
      return pc.getList(conf.http, [buffer.JAN], function(err, data) {
        if (err) {
          stream.emit('error', err);
          console.log("" + this.name + ": error = " + err);
          return;
        }
        if (data[0] != null) {
          return process.nextTick(function() {
            console.log("" + stream.name + ": data = " + (JSON.stringify(data[0])));
            stream.emit('data', data[0]);
            stream.outputLength++;
            return true;
          });
        } else {
          return console.log("" + this.name + ": JAN not found");
        }
      });
    };
    stream.end = function() {
      stream.emit('end');
      return console.log("" + this.name + " end: in=" + this.inputLength + ", out=" + this.outputLength + " : " + (new Date));
    };
    return stream;
  };

  /*
  ## main:
  */


  db.open(conf.db, function(err, client) {
    var Commodities, cursor, field, key, query;
    if (err) {
      throw err;
    }
    key = 'JAN';
    query = {};
    query[key] = {
      $ne: ''
    };
    field = {
      _id: 0
    };
    field[key] = 1;
    Commodities = client.collection('commodities');
    cursor = Commodities.find(query, field);
    return Sync(function() {
      var JANS, doc, getter, index, unit, updater;
      index = 0;
      unit = 10;
      JANS = [];
      updater = function(data) {
        var d, i, options, update, _i, _len, _results;
        _results = [];
        for (i = _i = 0, _len = data.length; _i < _len; i = ++_i) {
          d = data[i];
          query[key] = d.JAN;
          update = {
            $set: {
              pricecheck: d
            }
          };
          options = {
            safe: true
          };
          console.log('update: ', JSON.stringify(query), JSON.stringify(update), JSON.stringify(options));
          _results.push(Sync(function() {
            var doc;
            return doc = Commodities.update.sync(Commodities, query, update, options);
          }));
        }
        return _results;
      };
      getter = function() {
        var JAN, data, i, _i, _len;
        data = pc.getList.sync(null, conf.http, JANS);
        if (JANS.length === data.length) {
          updater(data);
        } else {
          console.log("data contains valid data");
          for (i = _i = 0, _len = JANS.length; _i < _len; i = ++_i) {
            JAN = JANS[i];
            data = pc.getList.sync(null, conf.http, [JAN]);
            if (data.length > 0) {
              updater(data);
            } else {
              updater([
                {
                  JAN: JAN,
                  asin: null
                }
              ]);
            }
          }
        }
        return JANS = [];
      };
      while ((doc = cursor.nextObject.sync(cursor)) !== null) {
        console.log(index + 1, doc);
        JANS[index % unit] = doc.JAN;
        if ((++index % unit) === 0) {
          getter();
        }
      }
      if (JANS.length > 0) {
        getter();
      }
      return client.close();
    });
  });

}).call(this);
