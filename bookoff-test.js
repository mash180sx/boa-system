// Generated by CoffeeScript 1.3.3
(function() {
  var bo, conf, getBOGenreList, getBOStockList;

  conf = require('./config');

  bo = require('./lib/bookoff');

  getBOGenreList = function(cb) {
    var _this = this;
    this.name = "getBOGenreList";
    this.retry = 0;
    setTimeout(function() {
      return bo.getBOGenreList(conf, function(err, result) {
        if (err === null) {
          return cb(null, result);
        }
        return console.log("Error: " + err);
      });
    }, 200);
    return setTimeout(function() {
      console.log("" + _this.name + ": retry=" + (++_this.retry));
      return process.nextTick(function() {
        return getBOGenreList(cb);
      });
    }, 15 * 1000);
  };

  getBOStockList = function(id, page, cb) {
    var _this = this;
    this.name = "getBOStockList";
    this.retry = 0;
    setTimeout(function() {
      return bo.getBOStockList(conf, id, page, function(err, result) {
        if (err === null) {
          return cb(null, result);
        }
        return console.log("Error: " + err);
      });
    }, 200);
    return setTimeout(function() {
      console.log("" + _this.name + ": retry=" + (++_this.retry));
      return process.nextTick(function() {
        return getBOStockList(id, page, cb);
      });
    }, 15 * 1000);
  };

  getBOGenreList(function(err, genres) {
    var genre, _i, _len, _results;
    if (err) {
      return console.log("Error: " + err);
    }
    console.log("test:", genres);
    _results = [];
    for (_i = 0, _len = genres.length; _i < _len; _i++) {
      genre = genres[_i];
      _results.push(getBOStockList(genre.id, 1, function(err, stocks) {
        if (err) {
          console.log("Error: " + err);
        }
        return console.log(stocks);
      }));
    }
    return _results;
  });

}).call(this);