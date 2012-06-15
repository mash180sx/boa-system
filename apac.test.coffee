apac = require './lib/apac'
conf = require './config'

JANS = ['9784338218023', '9784904336236']

apac.getApaclist conf.amazon, JANS, (err, items)->
  for item in items
    console.log JSON.stringify item, null, "  "

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