// Generated by CoffeeScript 1.3.1
(function() {
  var Stream, Sync, concate, conf, db, dbfind, dbupdate, pc, pcstream, skip, _ref;

  Sync = require('sync');

  _ref = require('./lib/stream'), Stream = _ref.Stream, concate = _ref.concate, dbfind = _ref.dbfind, dbupdate = _ref.dbupdate;

  conf = require('./config');

  pc = require('./lib/pricecheck');

  db = require('./lib/db');

  if (process.argv.length >= 3) {
    skip = Number(process.argv[2]);
    console.log("skip: " + skip);
  } else {
    skip = 0;
  }

  /*
  ##  stream : pipable stream
  ##
  ##  TODO: pause, resume or another unsupported
  ##        (to be referring the 'event-stream')
  */


  pcstream = function(unit) {
    var stream;
    if (unit == null) {
      unit = 1000;
    }
    stream = new Stream;
    stream.name = "pcstream";
    stream.writable = true;
    stream.readable = true;
    stream.inputLength = 0;
    stream.outputLength = 0;
    stream.unit = unit;
    stream.write = function(buffer) {
      stream.inputLength++;
      return pc.getPCInfolist(conf, [buffer.JAN], function(err, data) {
        var q;
        if (err) {
          stream.emit('error', err);
          console.log("" + this.name + ": error = " + err);
          return;
        }
        if (data[0] != null) {
          stream.emit('data', data[0]);
          stream.outputLength++;
          if ((q = stream.inputLength - stream.outputLength) >= stream.unit) {
            console.log("" + this.name + ": queue full");
            return false;
          } else if (q === 0) {
            console.log("" + this.name + ": drain");
            stream.emit('drain');
            return true;
          }
        } else {
          console.log("" + this.name + ": JAN not found");
          return true;
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
    var Commodities, ds, dus, duscb, field, key, options, pcs, query;
    if (err) {
      throw err;
    }
    key = 'JAN';
    query = {};
    query[key] = {
      $ne: ''
    };
    query.amazon = {
      $exists: false
    };
    field = {
      _id: 0
    };
    field[key] = 1;
    options = {
      sort: key
    };
    if (skip > 0) {
      options.skip = skip;
    }
    Commodities = client.collection('commodities');
    ds = dbfind(Commodities, query, field);
    pcs = pcstream();
    dus = dbupdate(Commodities, {}, [key]);
    ds.on('data', function(data) {
      if (pcs.write(data) === false) {
        return ds.pause();
      }
    });
    pcs.on('drain', function() {
      return ds.resume();
    });
    duscb = function() {
      console.log("dus start: ", new Date, ds.inputLength);
      return Sync(function() {
        while (true) {
          console.log("update: " + ds.outputLength + "/" + ds.inputLength);
          if (ds.outputLength < ds.inputLength) {
            Sync.sleep(15 * 1000);
          } else {
            client.close();
            return;
          }
        }
      });
    };
    return ds.pipe(pcs).pipe(dus).on('end', duscb);
  });

}).call(this);
