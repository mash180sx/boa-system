#
# casper [--proxy=proxy.XXXX:YYYY] ama.casper.coffee
#
###

# 在庫管理
#https://sellercentral.amazon.co.jp/myi/search/ProductSummary

###
casper = require("casper").create()
conf = require("./config")


# 在庫商品(すべての在庫商品)画面の表示(未サインインのため、この時点ではサインイン画面に遷移)
casper.start "https://sellercentral.amazon.co.jp/myi/search/ProductSummary", ->
  @viewport 1024, 768
  @capture "amatest1.png"

# サインイン画面にてemail、passwordを入力
casper.then ->
	@fill 'form[name=signin]', {
	  email: conf.amazon.email,
	  password: conf.amazon.password
	}, true

trs = []
getTrs = ->
	trs = document.querySelectorAll('tr[id|=sku]')
	Array::map.call trs, (el)->	el.getAttribute('id')
		
# 在庫商品(すべての在庫商品)画面に遷移
casper.then ->
  @capture "amatest2.png"
  trs = @evaluate getTrs
  for tr in trs
  	@echo tr

casper.run ->
  @exit()
