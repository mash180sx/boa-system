conf = require './config'
db = require './lib/db'

# TODO: to insert db following parameters
no_used_rate = 0.8
no_new_rate = 10.0

# TODO: to get following parameters from amazon web
#         http://www.amazon.co.jp/gp/help/customer/display.html?nodeId=1085246
commission = 0.15     # 販売手数料(暫定)       ：実際にはカテゴリ毎に異なる値
base_charge = 100     # 基本成約料             ：　小口出品時
category_charge = 140 # カテゴリー成約料(暫定)  ：実際にはカテゴリ毎に異なる値

out_collection = "temp"
limit = 0

db.open conf.db, (err, client)->
  if err then throw err

  Commodities = client.collection 'commodities'
  Temp = client.collection 'temp'
  Temp.drop()
  
  query = { $or: [
    {"amazon.old":{$gt:1000}}
    {"amazon.old":0, "amazon.new":0}
    {"amazon.old":0, "amazon.new":{$gt:1000}}]}
  fields = {_id:0, JAN:1, sku:1, "category.primary":1, "amazon.asin":1, "price.old":1, "price.new":1, "amazon.old":1, "amazon.new":1}
  options = {sort: "price.old"}

  index = 0
  map = (err, doc)->
    if err then throw err
    console.log index++, JSON.stringify(doc)
    if doc is null
      client.close()
      process.exit()
      return

    self = doc
    result = 
      JAN: self.JAN
      sku: self.sku
      asin: self.amazon.asin
      cat: self.category.primary
      pold: self.price.old
      pnew: self.price["new"]
      aold: self.amazon.old
      anew: self.amazon["new"]
    
    result.sales_price = sales_price =
      if (aold=self.amazon.old)>0
        if aold>(anew=self.amazon["new"])>0
          result.type = 1
          parseInt anew * no_used_rate
        else
          result.type = 2
          aold
      else if (anew=self.amazon.new)>0
        result.type = 3
        parseInt anew * no_used_rate
      else
        result.type = 4
        parseInt self.price.new * no_new_rate
    # TODO: total_cost : append delivery cost, commission, etc.
    result.net_price = net_price = self.price.old
    result.delivery_cost = delivery_cost = if net_price>1500 then 0 else 350
    result.total_cost = total_cost = net_price + delivery_cost
    
    result.total_commission = total_commission = sales_price*commission + base_charge + category_charge

    result.gross_profit = gross_profit = sales_price - total_cost - total_commission
    
    result.gross_profit_ratio = gross_profit_ratio = gross_profit / sales_price
    
    Temp.insert result
    
  if limit>0 then options.limit = limit
  Commodities.find(query, fields, options).each map
