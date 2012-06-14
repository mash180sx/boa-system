{OperationHelper} = require 'apac'

###
##
## apac (Amazon Product Advertising Client)による Amazon 情報取得
## 
##  ・JAN(EAN)により、最大10個まで検索
##  
## input      : conf コンフィギュレーション
##  = {
##    awsId: conf.awsId,
##    awsSecret: conf.awsSecret,
##    assocId: conf.assocId
##  }
## input      : JANS 配列（最大10件）
## output : callback(err, items) コールバック関数 items は Amazon 情報リスト(配列)
###

exports.getApaclist = (conf, JANS, cb)->
  # construct OperationHelper 
  params = 
    awsId: conf.awsId
    awsSecret: conf.awsSecret
    assocId: conf.assocId
    endPoint: conf.endPoint
  # slice JANS 10
  JANS = JANS.slice 0, 10
  #console.log JANS
  opHelper = new OperationHelper params
  
  # ItemLookup
  opHelper.execute 'ItemLookup',
    Condition: 'All'
    IdType: 'EAN'
    SearchIndex: 'All'
    ItemId: "#{JANS.join(',')}"
    ResponseGroup: "ItemAttributes,OfferSummary,SalesRank"
  , (err, results)->
    items = []
    for result, i in results.Items.Item
      items[i] =
        JAN: result.ItemAttributes.EAN
        ASIN: result.ASIN
        url: result.DetailPageURL
        title: result.ItemAttributes.Title
        author: result.ItemAttributes.Author
        "new": Number result.OfferSummary.LowestNewPrice.Amount
        old: Number result.OfferSummary.LowestUsedPrice.Amount
        rank: Number result.SalesRank
    cb err, items