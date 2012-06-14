require 'should'

{AmazonManager} = require '../amazon'
conf = require '../config'

describe 'AmazonManager', ->
  it 'should construct and invoke the callback instance without error', (done)->
    amaMan = new AmazonManager (err, am)->
      if err? then return done err
      am.should.be.an.instanceof AmazonManager
      am.should.equal amaMan
      done()

      describe '#signin', ->
        it 'should signin and get marketplaceID', (done)->
          am.api 'signin', conf.amazon, (err, marketplaceID)->
            if err? then return done err
            marketplaceID.should.equal 'A1VC38T7YXB528'
            done()

      describe '#productSummary', ->
        it 'should get productSummary', (done)->
          if err? then return done err
          am.api 'productSummary', (err, totalAmount)->
            totalAmount.should.equal 38
            done()

      describe '#productList', ->
        it 'should get productList', (done)->
          if err? then return done err
          am.api 'productList', (err, items)->
            items.length.should.equal 38
            for item in items
              item.should.have.keys('status', 'sku', 'release', 'condition', 'delivery', \
                'asin', 'title', 'amount', 'sellPrice', 'lowPrice', 'delPrice')
            done()
