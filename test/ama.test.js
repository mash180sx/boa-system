// Generated by CoffeeScript 1.3.1
(function() {
  var AmazonManager, conf;

  require('should');

  AmazonManager = require('../amazon').AmazonManager;

  conf = require('../config');

  describe('AmazonManager', function() {
    return it('should construct and invoke the callback instance without error', function(done) {
      var amaMan;
      return amaMan = new AmazonManager(function(err, am) {
        if (err != null) {
          return done(err);
        }
        am.should.be.an["instanceof"](AmazonManager);
        am.should.equal(amaMan);
        done();
        describe('#signin', function() {
          return it('should signin and get marketplaceID', function(done) {
            return am.api('signin', conf.amazon, function(err, marketplaceID) {
              if (err != null) {
                return done(err);
              }
              marketplaceID.should.equal('A1VC38T7YXB528');
              return done();
            });
          });
        });
        describe('#productSummary', function() {
          return it('should get productSummary', function(done) {
            if (err != null) {
              return done(err);
            }
            return am.api('productSummary', function(err, totalAmount) {
              totalAmount.should.equal(38);
              return done();
            });
          });
        });
        return describe('#productList', function() {
          return it('should get productList', function(done) {
            if (err != null) {
              return done(err);
            }
            return am.api('productList', function(err, items) {
              var item, _i, _len;
              items.length.should.equal(38);
              for (_i = 0, _len = items.length; _i < _len; _i++) {
                item = items[_i];
                item.should.have.keys('status', 'sku', 'release', 'condition', 'delivery', 'asin', 'title', 'amount', 'sellPrice', 'lowPrice', 'delPrice');
              }
              return done();
            });
          });
        });
      });
    });
  });

}).call(this);
