{AmazonManager} = require './lib/amazon'
db = require './lib/db'
conf = require './config'

marketplaceID = null
options = debug:1
if conf.http.proxy? then options.proxy = "#{conf.http.proxy}:#{conf.http.port}"
amaMan = new AmazonManager options, (err, ama)->
  if err then throw err
  # amazon api definitions
  ###
  totalAmount = am.api.sync am, 'productSummary'
  console.log "totalAmount: #{totalAmount}"
  ###
  
  ###
  items = am.api.sync am, 'productList'
  console.log "items: #{items} items.length: #{items.length}"
  for item, i in items
    console.log "item[#{i}]: #{JSON.stringify item}"
  ###
  
  ###
  result = am.api.sync am, 'remove',
    asin: '4274067149'
  console.log "result:#{result}"
  ###
  signin = (conf=conf.amazon, cb)->
    ama.api 'signin', conf, (err, mID)->
      marketplaceID = mID
      console.log "signin complete: #{new Date}"
      console.log "marketplaceID: #{marketplaceID}"
      cb err, marketplaceID
    
    ###
    result = am.api.sync am, 'add',
      asin:'477414813X'   ## 必須
      sellPrice: 3024     ## 必須
      condition: 'Used|LikeNew'
      conditionNote: 'ほぼ新品同様で美品です。'
    console.log "result: #{result}"
    ###
  add = (product, cb)->
    product.amount = 1
    product.condition ?= 'Used|Acceptable'
    product.conditionNote ?= '多少きず等ありますが使用には支障のないレベルです。'
    ama.api 'add', product, (err, result)->
      console.log "result:#{result}"
      cb err, result

    ###
    result = am.api.sync am, 'update',
      asin: '4274067149'
      marketplaceID: marketplaceID
      sellPrice: 3249
      amount: 0
      condition: 'Used|Acceptable'
      conditionNote: '多少きず等ありますが使用には支障のないレベルです。'
    console.log "result:#{result}"
    ###
  update = (product, cb)->
    product.marketplaceID ?= marketplaceID
    ama.api 'update', product, (err, result)->
      console.log "result:#{result}"
      cb err, result

  signout = ->
    ama.api 'signout', (err) ->
      console.log 'signout complete'
  
  # <<<<<<<<<< Main loop >>>>>>>>>>
  db.open conf.db, (err, client)->
    if err then throw err
    
    Temp = client.collection 'temp'
    
    # <<<<<<<<<< price check >>>>>>>>>>
    # TODO: 出店中の商品の値洗い
    #       ・最安値をキープする
    #       ・gross_profitが1000未満になったものは管理外とする
    #       ・gross_profit_rationが0.6未満になったものは管理外とする
    min_gross_profit = 1000
    min_gross_profit_ratio = 0.6
    # <<<<<<<<<< stock check >>>>>>>>>>
    # TODO: 出店中の商品の在庫確認
    #       ・在庫がないものは管理外とする
    
