Sync = require 'sync'
{AmazonManager} = require './lib/amazon'

conf = require './config'

options = debug:1, proxy: 'proxy.toshiba.co.jp:8080'
amaMan = new AmazonManager options, (err, am)->
  Sync ->
    console.log new Date
    marketplaceID = am.api.sync am, 'signin', conf.amazon
    console.log "signin complete: #{new Date}"
    console.log "marketplaceID: #{marketplaceID}"

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
    result = am.api.sync am, 'add',
      asin:'477414813X'   ## 必須
      sellPrice: 3024     ## 必須
      condition: 'Used|LikeNew'
      conditionNote: 'ほぼ新品同様で美品です。'
    console.log "result: #{result}"
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
    result = am.api.sync am, 'remove',
      asin: '4274067149'
    console.log "result:#{result}"
    ###

    am.api 'signout', (err) ->
    console.log 'signout complete'
  


###
spawn = require('child_process').spawn

casper = spawn 'casperjs', ['ama.casper.coffee']
casper.stdout.on 'data', (data)->
	console.log 'stdout:', data.toString()
casper.stdout.on 'error', (data)->
  console.log 'stderr:', data.toString()
casper.on 'exit', (code)->
  console.log 'exited:', code
	

#Sync = require 'sync'
Browser = require "zombie"
conf = require "./config"

browser = new Browser
  debug: true,
  waitFor: 5000

if conf.http.proxy
  browser.proxy = "http://#{conf.http.proxy}:#{conf.http.port}"

# アマゾン出品アカウントサインインURL  
amaOpUrl = "https://sellercentral.amazon.co.jp/myi/search/ProductSummary"
#amaOpUrl = "http://www.google.com"

# エラーハンドラ
browser.on 'error', (err)->
	browser.log err

idx = 0
browser.on 'loaded', (brw)->
	browser.log "The page[#{++idx}]:#{browser.location}"

# 上記URLでサイト訪問
browser.visit amaOpUrl
  browser.log "The page:#{browser.html()}"
  browser.fill('#email', conf.amazon.email)
  .fill('#password', conf.amazon.password)
  .pressButton('signin')

browser.wait 5*1000, ->
	browser.dump()
	browser.log "The page:#{browser.html()}"
	return

browser.wait ()->
    console.log "The.page:#{browser.html()}"
    # サインイン画面になるのでフォーム入力
    browser.fill('#email', conf.amazon.email)
    .fill('#password', conf.amazon.password)
    browser.wait(
      ()-> browser.document.signin.submit(),
      ()-> console.log "confirm.page:#{browser.html()}")
    return

# 出品アカウント サインイン
#https://www.amazon.co.jp/ap/signin?_encoding=UTF8&openid.assoc_handle=jpflex&openid.claimed_id=http%3A%2F%2Fspecs.openid.net%2Fauth%2F2.0%2Fidentifier_select&openid.identity=http%3A%2F%2Fspecs.openid.net%2Fauth%2F2.0%2Fidentifier_select&openid.mode=checkid_setup&openid.ns=http%3A%2F%2Fspecs.openid.net%2Fauth%2F2.0&openid.ns.pape=http%3A%2F%2Fspecs.openid.net%2Fextensions%2Fpape%2F1.0&openid.pape.max_auth_age=900&openid.return_to=https%3A%2F%2Fwww.amazon.co.jp%2Fgp%2Fseller-account%2Fmanagement%2Fyour-account.html%3Fie%3DUTF8%26ref_%3Dya__1

# 在庫管理
#https://sellercentral.amazon.co.jp/myi/search/ItemSummary.amzn?_encoding=UTF8&ref_=im_invmgr_dnav_home_
#https://sellercentral.amazon.co.jp/myi/search/ItemSummary.amzn?_encoding=UTF8&ref_=im_invmgr_mmap_home

# 商品詳細
#https://catalog-sc.amazon.co.jp/abis/product/DisplayEditProduct?sku=JW-GF8T-H5AE&asin=B000J878BW&marketplaceID=A1VC38T7YXB528
#https://sellercentral.amazon.co.jp/myi/search/ItemSummary.amzn?_encoding=UTF8&ref_=im_invmgr_mmap_home
###

