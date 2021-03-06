// Generated by CoffeeScript 1.3.3
(function() {
  var conf, db, limit, no_new_rate, no_used_rate, out_collection, total_size;

  conf = require('./config');

  db = require('./lib/db');

  no_used_rate = 0.8;

  no_new_rate = 10.0;

  out_collection = "temp";

  limit = 10000;

  total_size = 1000;

  db.open(conf.db, function(err, client) {
    var Commodities, index, map, options, query, reduce, scope;
    if (err) {
      throw err;
    }
    Commodities = client.collection('commodities');
    query = {
      $or: [
        {
          "amazon.old": {
            $gt: 1000
          }
        }, {
          "amazon.old": 0,
          "amazon.new": 0
        }, {
          "amazon.old": 0,
          "amazon.new": {
            $gt: 1000
          }
        }
      ]
    };
    index = 0;
    map = function() {
      var anew, aold, delivery_cost, gross_profit, gross_profit_ratio, key, net_price, result, sales_price, total_cost, _ref;
      key = {
        JAN: this.JAN,
        asin: this.amazon.asin
      };
      result = {
        pold: this.price.old,
        pnew: this.price["new"],
        cat: this.category.primary,
        aold: this.amazon.old,
        anew: this.amazon["new"]
      };
      sales_price = (aold = this.amazon.old) > 0 ? (aold > (_ref = (anew = this.amazon["new"])) && _ref > 0) ? (result.type = 1, parseInt(anew * no_used_rate)) : (result.type = 2, aold) : (anew = this.amazon["new"]) > 0 ? (result.type = 3, parseInt(anew * no_used_rate)) : (result.type = 4, parseInt(this.price["new"] * no_new_rate));
      net_price = this.price.old;
      delivery_cost = net_price > 1500 ? 0 : 350;
      total_cost = net_price + delivery_cost;
      result.gross_profit = gross_profit = sales_price - total_cost;
      result.gross_profit_ratio = gross_profit_ratio = gross_profit / sales_price;
      emit(key, result);
    };
    reduce = function(key, values) {
      if (values.length > 1) {
        console.log("values.length: " + values.length);
      }
      return values[0];
    };
    scope = {
      no_used_rate: no_used_rate,
      no_new_rate: no_new_rate
    };
    options = {
      out: {
        merge: out_collection
      },
      query: query,
      scope: scope
    };
    if (limit > 0) {
      options.limit = limit;
    }
    /*
      mapReduce = (i, skip)->
        console.log "do mapReduce(#{i}, #{skip})"
        if skip>0 then options.skip = skip
        Commodities.mapReduce map, reduce, options, (err, collection)->
          if err then throw err
          query2 = {} #gross_profit: {$gt: 1000}
          options2 = sort: [["value.gross_profit", -1]]
          collection.find(query2, {}, options2).each (err, doc)->
            if err then throw err
            console.log index++, JSON.stringify(doc)
            if doc is null
              if skip is total_size
                client.close()
                process.exit()
              else
                mapReduce i+1, skip+limit
      
      mapReduce 0, 0
    */

    return Commodities.mapReduce(map, reduce, options, function(err, collection) {
      var options2, query2;
      if (err) {
        throw err;
      }
      query2 = {};
      options2 = {
        sort: [["value.gross_profit", -1], ["value.gross_profit_ratio", 1]]
      };
      return collection.find(query2, {}, options2).each(function(err, doc) {
        if (err) {
          throw err;
        }
        console.log(index++, JSON.stringify(doc));
        if (doc === null) {
          client.close();
          return process.exit();
        }
      });
    });
    /*
      cursor = collection.find()
      loop
        cursor.nextObject (err, doc)->
          if err then throw err
          console.log index++, JSON.stringify(doc)
          if doc is null
            client.close()
            process.exit()
    */

  });

}).call(this);
