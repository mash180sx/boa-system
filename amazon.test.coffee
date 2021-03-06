Sync = require 'sync'
apac = require './lib/apac'
db = require './lib/db'
conf = require './config'

###
TODO: Amazon Product Advertising-API limitation...
{ '@': { xmlns: 'http://ecs.amazonaws.com/doc/2010-11-01/' },
  Error: 
   { Code: 'AccountLimitExceeded',
     Message: 'Account limit of 2000 requests per hour exceeded.' },
  RequestId: 'a16a01ad-6686-4853-9035-03c8bc12b001' }
###


#JANS = ['9784338218023', '9784904336236', '4961524093489', '4988132848386', '4956027125089', 'aaaslk']
#JANS = ['9784338218023', '9784904336236']
JANS = ['4582200671847','9784416495087','4988003366773','4988104069276','9784391116977','9784167228033','9784276435827','9784863321892','9784840732673','4988008632835']

apac.getApaclist conf.amazon, JANS, (err, items)->
  console.log items
  #for item, j in items
  #  console.log j, JSON.stringify item

###
# callback for db.open
dbcb = (err, client)->
  if err then throw err
  
  console.log "dbcb start"
  Categories = client.collection 'categories'
  Commodities = client.collection 'commodities'
  
  JANS = []
  index = 0
  stream = Commodities.find({JAN: {$exists:1}}, {JAN:1, _id:0}).stream()

  stream.on 'data', (doc)->
    if doc?
      JANS[index%10] = doc.JAN
      if (++index)%10 is 0
        #console.log JSON.stringify JANS
        apac.getApaclist conf.amazon, JANS, (err, items)->
          Sync ->
            #console.log items
            for item, j in items
              #console.log j, JSON.stringify item
              Sync.sleep 500
        JANS = []
    else
      if JANS?.length>0
        apac.getApaclist conf.amazon, JANS, (err, items)->
          Sync ->
            #console.log items
            for item, j in items
              #console.log j, JSON.stringify item
              Sync.sleep 500
      client.close

# ////////// DB open //////////
db.open conf.db, dbcb
###

###
TODO: 
> db.commodities.findOne({"category.primary":"CD"})
{
        "title" : "センチメンタル・グラフィティＶー想い出のスクールデイズ１"
        "category" : {
                "primary" : "CD",
                "sub" : [
                        "アニメ・ゲーム",
                        "その他"
                ]
        },
        "url" : {
                "item" : "http://click.linksynergy.com/link?id=W5C7AFzKcVo&offerid=214771.10001115202&type=15&murl=http%3A%2F%2Fwww.bookoffonline.co.jp%2Fold%2F0001115202",
                "image" : "http://www.bookoffonline.co.jp/images/goods/item_m.gif"
        },
        "type" : "中古",
        "author" : "（ドラマＣＤ）",
        "sku" : "0001115202",
        "JAN" : "4961524093489",
        "price" : {
                "fixed" : 2625,
                "new" : 2625,
                "old" : 250,
                "buy" : 0
        },
        "release" : ISODate("1998-06-26T15:00:00Z"),
        "mount" : 0,
        "update" : ISODate("2012-06-14T20:21:25Z"),
        "_id" : ObjectId("4fdaeb6317081f0a5300000f")
}
> db.commodities.findOne({"category.primary":"DVD・ビデオ"})
{
        "title" : "スリーパーズ＜ＤＴＳ　ＥＤＩＴＩＯＮ＞"
        "category" : {
                "primary" : "DVD・ビデオ",
                "sub" : [
                        "DVD",
                        "洋画",
                        "その他"
                ]
        },
        "url" : {
                "item" : "http://click.linksynergy.com/link?id=W5C7AFzKcVo&offerid=214771.10010809266&type=15&murl=http%3A%2F%2Fwww.bookoffonline.co.jp%2Fold%2F0010809266",
                "image" : "http://www.bookoffonline.co.jp/goodsimages/M/001080/0010809266M.jpg"
        },
        "type" : "中古",
        "author" : "バリー・レヴィンソン（製作・脚本・監督）~~ブラッド・ピット~~ロバート・デ・ニーロ~~ダスティン・ホフマン",
        "sku" : "0010809266",
        "JAN" : "4988132848386",
        "price" : {
                "fixed" : 2100,
                "new" : 2625,
                "old" : 950,
                "buy" : 0
        },
        "release" : ISODate("2006-07-18T15:00:00Z"),
        "mount" : 0,
        "update" : ISODate("2012-06-14T20:21:25Z"),
        "_id" : ObjectId("4fdaeb6317081f0a5300000b")
}
> db.commodities.findOne({"category.primary":"ゲーム・おもちゃ"})
{
        "title" : "イースＩ＆ＩＩ・ＳＥＶＥＮセット(イースポストカード８枚セット付)(イースポストカード８枚セット付)",
        "category" : {
                "primary" : "ゲーム・おもちゃ",
                "sub" : [
                        "ゲーム機",
                        "テレビゲーム",
                        "PSP"
                ]
        },
        "url" : {
                "item" : "http://click.linksynergy.com/link?id=W5C7AFzKcVo&offerid=214771.10016318731&type=15&murl=http%3A%2F%2Fwww.bookoffonline.co.jp%2Fold%2F0016318731",
                "image" : "http://www.bookoffonline.co.jp/goodsimages/M/001631/0016318731M.jpg"
        },
        "type" : "中古",
        "author" : "イースＩ＆ＩＩ・ＳＥＶＥＮセット(イースポストカード８枚セット付)(イースポストカード８枚セット付)",
        "sku" : "0016318731",
        "JAN" : "4956027125089",
        "price" : {
                "fixed" : 7182,
                "new" : 7980,
                "old" : 6450,
                "buy" : 3400
        },
        "release" : ISODate("2010-03-17T15:00:00Z"),
        "mount" : 0,
        "update" : ISODate("2012-06-14T20:21:25Z"),
        "_id" : ObjectId("4fdaeb6317081f0a5300001b")
}
>
###