phantom = require 'phantom'
conf = require './config'
{EventEmitter} = require 'events'

#    Amazon テスト用コード
#1.出品用アカウント サインイン画面
#　 https://www.amazon.co.jp/ap/signin?_encoding=UTF8&openid.assoc_handle=jpflex&openid.claimed_id=http%3A%2F%2Fspecs.openid.net%2Fauth%2F2.0%2Fidentifier_select&openid.identity=http%3A%2F%2Fspecs.openid.net%2Fauth%2F2.0%2Fidentifier_select&openid.mode=checkid_setup&openid.ns=http%3A%2F%2Fspecs.openid.net%2Fauth%2F2.0&openid.ns.pape=http%3A%2F%2Fspecs.openid.net%2Fextensions%2Fpape%2F1.0&openid.pape.max_auth_age=900&openid.return_to=https%3A%2F%2Fwww.amazon.co.jp%2Fgp%2Fseller-account%2Fmanagement%2Fyour-account.html%3Fie%3DUTF8%26ref_%3Dya__1
#
#　 form[name=signin]
#    document.getElementById("email").value = email
#    document.getElementById("password").value = password
#    { email, password }
#    document.signin.submit()  ???
#
#2.在庫管理(在庫一覧)
#
#  https://sellercentral.amazon.co.jp/myi/search/ProductSummary
#  { sku, asin, title, release, amount, condition, price, otherprice, fba }
#
#3.出品を追加
#3.1.商品を登録(出品商品のASINなどを入力)
#
#  https://sellercentral.amazon.co.jp/gp/ezdpc-gui/start.html/ref=im_addlisting_dnav_home_
#  form[name=itemSearchForm]
#  input#searchStringTextId
#    TODO: 本の場合はISBNで詳細が表示される。他の場合も調査要
#          例．4774146293　(ISBN 実践JS)
#  document.itemSearchForm.submit() ???
#3.2.商品を登録(検索結果 ISBNの場合　　注：商品名の場合は異なった動き)
#  内容はほぼ3.1に検索結果が追加された画面。POST結果により以下のURLにRedirectされている
#    https://catalog-sc.amazon.co.jp/abis/ItemSearch/Search
#  TODO: ISBNで絞りこまれているため、submitだけでOK???...
#  TODO: いや、<button ... onclick="itemSelected('4774146293');">が必要だろう。
#
#  form[name=itemSelectedForm]
#  itemSelected(__isbn_str__)
#    TODO:その後、必要があれば以下
#  document.itemSelectedForm.submit() ???
#  

# phantom : evaluate用のグローバル設定処理
setGlobal = (page, name, data) ->
  json = JSON.stringify(data)
  fn = "return window[#{JSON.stringify(name)}]=#{json};"
  page.evaluate(new Function(fn))

viewSize = { width:1024, height:768 }
# phantomスタート
phantom.create (ph) ->
  # webpage作成
  ph.createPage (page) ->
    # onLoadFinished
    # page.route にルート(Number)を入力する
    class AmaMan extends EventEmitter
      constructor: ->
        @route = 0
      trigger: ->
        @route++
        console.log "emit 'next', #{@route}"
        @emit 'next', @route

    amaMan = new AmaMan

    #page.set 'viewportSize', viewSize
    page.set('onConsoleMessage', (msg)-> 
      console.log "sandbox: #{msg}"
      return)
    page.set('onLoadStarted', -> console.log 'Start loading')
    page.set('onLoadFinished', (status)->
      page.evaluate ->
        console.log "title:#{document.title}"
        return
      route = amaMan.route
      console.log "route: #{route}, status: #{status}"
      page.render "amatest#{route}.png"
      amaMan.trigger()
      return)
    

    amaMan.on 'next', (route)->
      switch route
        when 1
          # 1.出品用アカウント サインイン画面
          page.open "https://www.amazon.co.jp/ap/signin?_encoding=UTF8&openid.assoc_handle=jpflex&openid.claimed_id=http%3A%2F%2Fspecs.openid.net%2Fauth%2F2.0%2Fidentifier_select&openid.identity=http%3A%2F%2Fspecs.openid.net%2Fauth%2F2.0%2Fidentifier_select&openid.mode=checkid_setup&openid.ns=http%3A%2F%2Fspecs.openid.net%2Fauth%2F2.0&openid.ns.pape=http%3A%2F%2Fspecs.openid.net%2Fextensions%2Fpape%2F1.0&openid.pape.max_auth_age=900&openid.return_to=https%3A%2F%2Fwww.amazon.co.jp%2Fgp%2Fseller-account%2Fmanagement%2Fyour-account.html%3Fie%3DUTF8%26ref_%3Dya__1"
        when 2
        	# 1.2.form をフィルしてsubmit

          # setGlobal conf.amazon
          setGlobal page, '__conf__', conf.amazon

          # form fill and submit
          page.evaluate ->
            document.querySelector("input#ap_email").value = __conf__.email
            document.querySelector("input#ap_password").value = __conf__.password
            document.querySelector("form#ap_signin_form").submit()
        when 3
          #2.在庫管理(在庫一覧)
          #  TODO: 時々 複数の onLoadFinished が呼ばれる場合がある。解析要！！
          #  TODO: marketplaceID をこの時点で取得できないか解析要！！
          page.open "https://sellercentral.amazon.co.jp/myi/search/ProductSummary"
        when 4
          #2.1.在庫管理（在庫一覧）
          #  以下の情報を取得する。
          #    marketplaceID -> input type="hidden" name="marketplaceID" value
          #    全商品数 -> <div id="pageListing"><strong>XX</strong>商品</div>
          #
          #  ページ当りの商品数を250とし(予め設定)、ページ数は計算して求める。
          #  searchController.gotoPage(_P_)でページ移動が可能
          #
          #  追加の場合、まずは商品一覧にないか全検索し、なければ追加を実施する。
          #  以下のようにして各商品の情報を取得
          #    items = document.querySelectorAll('input[name^=price]')
          #      <input name="price|FR-KP0J-MKU2|4774146293" value="2,849"
          #  また、商品のステータスを以下のように取得
          #    trs = document.querySelectorAll('tr[id|=sku]')
          #  各tdは以下のような順番で格納されている
          #    td(1) -> <td><input type="hidden" name="sku" value="XX-XXXX-XXXX">
          #    td(2) -> <td><input type="checkbox"
          #    td(3) -> <td><span...><a href="#" >変更</a><a href=...>▼</a>
          #    td(4) -> <td class="alignleft">出品中</td>
          ph.exit()
        when 4
          #3.出品を追加
          #3.1.商品を登録(出品商品のASINなどを入力)
          #
          #  https://sellercentral.amazon.co.jp/gp/ezdpc-gui/start.html/ref=im_addlisting_dnav_home_
          #  form[name=itemSearchForm]
          #  input#searchStringTextId
          #    TODO: 本の場合はISBNで詳細が表示される。他の場合も調査要
          #          例. 4774146293　(ISBN 実践JS)
          #  document.itemSearchForm.submit() ???
          #  上記はURLでは iframe を使用して下記カタログ検索画面を表示している。こちらを使用する！！
          #  https://catalog-sc.amazon.co.jp/abis/syh/SCIdentify.amzn?_encoding=UTF8&ref_=im_addlisting_dnav_home_
          page.open "https://catalog-sc.amazon.co.jp/abis/syh/SCIdentify.amzn?_encoding=UTF8&ref_=im_addlisting_dnav_home_"
        when 5
          # 3.1.2.form をフィルしてsubmit

          # setGlobal conf.amazon
          setGlobal page, '__conf__', conf.amazon

          # form fill and submit
          page.evaluate ->
            document.querySelector('input#searchStringTextId').value = "477414813X"
            document.querySelector("form[name='itemSearchForm']").submit()
        when 6
          #3.2.商品を登録(検索結果 ISBNの場合　　注：商品名の場合は異なった動き)
          #  内容はほぼ3.1に検索結果が追加された画面。POST結果により以下のURLにRedirectされている
          #    https://catalog-sc.amazon.co.jp/abis/ItemSearch/Search
          #  ##TODO: ISBNで絞りこまれているため、submitだけでOK???...
          #   <button ... onclick="itemSelected('4774146293');">が必要だろう。 
          #   →　必要！！　エラーメッセージのようなものが表示されるが気にしないこと！
          #
          #  form[name=itemSelectedForm]
          #  itemSelected(__isbn_str__)
          #    TODO:その後、必要があれば以下　→　必要！　実施
          #  document.itemSelectedForm.submit() !!
          
          # setGlobal conf.amazon
          setGlobal page, '__conf__', conf.amazon

          # form fill and submit
          page.evaluate ->
            itemSelected('477414813X')
            document.itemSelectedForm.submit()
        when 7
          #3.3.商品提供の情報を登録
          #  具体的に出品情報を登録する。以下のURLにRedirectされている
          #    https://catalog-sc.amazon.co.jp/abis/Display/ItemSelected
          #    TODO: Form Dataとしては asin, marketplaceIDとなっている。
          #          フォームデータだけ渡してこのページをダイレクトに表示できると思われる
          #  入力項目は以下とする（必須項目は頭に*を付加）
          #   * コンディション
          #        id="offering_condition" value="Used|Acceptable" 中古 – 可
          #     コンディション説明
          #        id="offering_condition_note" 
          #   * 販売価格
          #        id="our_price"
          #   * 在庫
          #        id="Offer_Inventory_Quantity"
          #   TODO: 国内配送が4日から7日以内となっているので現時点では以下は入力しないこととする
          #     商品の入荷予定日　ブックオフからの入荷日を2日として今日+2日で入力(YYYY/MM/DD)
          #
          #  form[name=productForm]
          #
          #  productTableController.buttonClicked('productTableSaveAndFinish')
          #  document.productForm.submit() !!
          
          # setGlobal conf.amazon
          setGlobal page, '__conf__', conf.amazon

          # form fill and submit
          page.evaluate ->
            #console.log "when 7: #{document.querySelector('#searchStringTextId').id}"
            #otherprice = document.querySelector("a[href$='condition=used']").parentNode.querySelector('span')
            #console.log "otherprice=#{otherprice}"
            document.querySelector('#offering_condition').value = "Used|Acceptable"
            document.querySelector('#offering_condition_note').value = "多少きず等ありますが読書するのには支障がないレベルです。"
            document.querySelector('#our_price').value = "5100"
            document.querySelector('#Offer_Inventory_Quantity').value = 1
            productTableController.buttonClicked('productTableSaveAndFinish')
            document.productForm.submit()
        when 8
          #3.4.商品提供情報の更新
          # TODO: 詳細の編集は以下のURL (sku, asin, marketplaceID が必要)
          #   https://catalog-sc.amazon.co.jp/abis/product/DisplayEditProduct?sku=FR-KP0J-MKU2&asin=4774146293&marketplaceID=A1VC38T7YXB528

          # setGlobal conf.amazon
          item = { sku: 'FR-KP0J-MKU2', asin: '4774146293', marketplaceID: 'A1VC38T7YXB528' }
          setGlobal page, '__item__', item
          
          page.open "https://catalog-sc.amazon.co.jp/abis/product/DisplayEditProduct?sku=#{item.sku}&asin=#{item.asin}&marketplaceID=#{item.marketplaceID}"
        when 9
          #3.4.商品提供情報の更新
          #3.4.2 具体的な値の追加と保存（更新）
          #  入力内容については3.3.の追加と同様。（画面も共有したような構成になっている）
          #
          #   * 販売価格
          #        id="our_price"
          #   * 在庫
          #        id="Offer_Inventory_Quantity"
          # form fill and submit
          page.evaluate ->
            document.querySelector('#our_price').value = "2900"
            document.querySelector('#Offer_Inventory_Quantity').value = 2
            productTableController.buttonClicked('productTableSaveAndFinish')
            document.productForm.submit()
          
        else
          # TODO: 再出品は以下のURL
          #  https://catalog-sc.amazon.co.jp/abis/edit/RelistProduct.amzn?sku=KO-6HDJ-U0S5&asin=4881357018&marketplaceID=A1VC38T7YXB528
          #setTimeout -> 
          #  page.render "amatest5.png"
          #  amaMan.trigger()
          #  return
          #, 1000
          
          
          ph.exit()
      return

    # amaMan start
    amaMan.trigger()

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

casper.thenEvaluate (email, password) ->
  document.getElementById("email").value = email
  document.getElementById("password").value = password
  document.signin.submit()
  return
,
  email: conf.amazon.email
  password: conf.amazon.password

trs = []
getTrs = ->
  trs = document.querySelectorAll('tr[id|=sku]')
  Array::map.call trs, (el)-> el.getAttribute('id')
    
# 在庫商品(すべての在庫商品)画面に遷移
casper.then ->
  @capture "amatest2.png"
  trs = @evaluate getTrs
  for tr in trs
    @echo tr

casper.run ->
  @exit()
###				