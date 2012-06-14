phantom = require 'phantom'
{EventEmitter} = require 'events'

###
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
###  

exports.AmazonManager = class AmazonManager extends EventEmitter
  api: (method, args={}, callback=->) ->
    if @methods[method]?   # exists method
      @args = if typeof args isnt "function" then args
      @callback = callback = if typeof args is "function" then args else callback
      console.log "calling api ('#{method}', {#{JSON.stringify(args)}}, #{callback})" if @debug?
      @methods[method]()
    else    # not exists method
      callback 901, new Error('No such method')
    
  constructor: (options={}, cb=->) ->
    if typeof options is "function" then cb = options
    # options.proxy = {proxy:proxy, port:port}
    if options.proxy? then @proxy = options.proxy
    if options.debug? then @debug = true
    ##TODO: 追加ポイント１
    @methods =
      # サインインして marketplaceID 取得
      # TODO: 自動サインアウト
      'signin': =>
        ##  引数チェック  必須: email, password
        if not(@args.email?) or not(@args.password?)
          return @callback new Error('Bad argument')
        @route = 'signin'
        @trigger()
      
      # 在庫管理画面にて 全商品数を取得
      'productSummary': =>
        @route = 'productSummary'
        @trigger()
      
      # 在庫管理画面にて 全商品listを取得
      'productList': =>
        @route = 'productList'
        @trigger()
      
      # 追加
      # TODO: premium係数、nius係数を使用し、販売価格を自動計算させる
      'add': =>
        ##  引数チェック  必須: asin, sellPrice
        if not(@args.asin?) or not(@args.sellPrice?)
          return @callback new Error('Bad argument')
        @premium = if @args.premium? then @args.premium else 5 # プレミアム係数（default：新品の5倍）
        @nius = if @args.nius? then @args.nius else 0.8 # not in used stock 中古在庫なしの新品との係数
        @route = 'add-catalog'
        @trigger()
      
      # 更新
      'update': =>
        ##  引数チェック  必須: asin, marketplaceID
        if not(@args.asin?) or not(@args.marketplaceID?)
          return @callback new Error('Bad argument')
        @route = 'update'
        @trigger()
      
      # 出品終了
      # TODO: 未完成
      'remove': =>
        ##  引数チェック  必須: asin
        if not(@args.asin?)
          return @callback new Error('Bad argument')
        @route = 'remove'
        @trigger()
      
      # 出品再開
      'resale': =>
      
      # サインアウト
      'signout': =>
        @route = 'signout'
        @trigger()
      
    # phatom用ルーティング定義
    ##TODO: 追加ポイント２
    @routes = [
      'signin'
      'signin-onload'
      'signin-complete'
      'productSummary'
      'productSummary-onload'
      'productList'
      'productList-onload'
      'productList-loop'
      'resale'
      'resale-onload'
      'add-catalog'
      'add-catalog-onload'
      'add-select'
      'add-fillsubmit'
      'add-complete'
      'update'
      'update-onload'
      'update-loop'
      'update-fillsubmit'
      'update-complete'
      'signout'
      'signout-onload'
    ]
    
    # phantom : evaluate用のグローバル設定処理
    setGlobal = (page, name, data) ->
      json = JSON.stringify(data)
      fn = "return window[#{JSON.stringify(name)}]=#{json};"
      page.evaluate(new Function(fn))

    viewSize = { width:1280, height:1024 }

    # phantomスタート
    # TODO: options.proxy の設定
    opts = 
    phantom.create (ph) =>
      @phantom = ph
      # webpage作成
      ph.createPage (page) =>
        @page = page
        
        page.set 'viewportSize', viewSize
        
        page.set('onConsoleMessage', (msg) => 
          console.log "sandbox: #{msg}" if @debug?
          return)
        page.set('onLoadStarted', =>
          console.log "Start loading -- route: #{@route}" if @debug?)
        page.set('onLoadFinished', (status) =>
          page.evaluate (->
            console.log "title:#{document.title}"
            window.location.href
          ), (result)=>
            page.location = result
            console.log "page.location: '#{page.location}'" if @debug?
            console.log "Load finished -- route: #{@route}, status: #{status}" if @debug?
            page.render "amaMan-#{@route}.png" if @debug?
            @trigger(status)
            return)
      
        @trigger = (status='internal') =>
          console.log "emit '#{status}'   ('#{@route}')" if @debug?
          @emit 'route', status
        
        @on 'route', (status)=>
          console.log "on 'route', ('#{status}')   : '#{@route}'" if @debug?
          switch @route
            when 'signin'
              ##1.出品用アカウント サインイン画面
              page.open "https://www.amazon.co.jp/ap/signin?_encoding=UTF8&openid.assoc_handle=jpflex&openid.claimed_id=http%3A%2F%2Fspecs.openid.net%2Fauth%2F2.0%2Fidentifier_select&openid.identity=http%3A%2F%2Fspecs.openid.net%2Fauth%2F2.0%2Fidentifier_select&openid.mode=checkid_setup&openid.ns=http%3A%2F%2Fspecs.openid.net%2Fauth%2F2.0&openid.ns.pape=http%3A%2F%2Fspecs.openid.net%2Fextensions%2Fpape%2F1.0&openid.pape.max_auth_age=900&openid.return_to=https%3A%2F%2Fwww.amazon.co.jp%2Fgp%2Fseller-account%2Fmanagement%2Fyour-account.html%3Fie%3DUTF8%26ref_%3Dya__1"
              #@route = 'idle'
              @route = 'signin-onload'
            when 'signin-onload'
              ##1.2.form をフィルしてsubmit
              
              # setGlobal conf.amazon
              setGlobal page, '__args__', @args

              # form fill and submit
              page.evaluate ->
                document.querySelector("input#ap_email").value = __args__.email
                document.querySelector("input#ap_password").value = __args__.password
                document.querySelector("form#ap_signin_form").submit()
              @route = 'signin-complete'
            when 'signin-complete'
              ##1.3. marketplaceIDを取得して callback
              page.get 'content', (result)=>
                #console.log "page.content: #{result}"
                re = result.match(/ue_mid='(\w+)'/)
                console.log "re:#{re}, RegExp.$1:#{RegExp.$1}" if @debug?
                console.log "marketplaceID(ue_mid) = #{RegExp.$1}" if @debug?
                @callback null, RegExp.$1

            when 'productSummary'
              ##2.在庫管理：サマリ取得（全商品数を取得して callback）
              ##  TODO: 時々 複数の onLoadFinished が呼ばれる場合がある。解析要！！
              ##  TODO: Webページ取得に時間がかかる点を考慮必要。
              @route = 'productSummary-onload'
              page.open "https://sellercentral.amazon.co.jp/myi/search/ProductSummary"
            when 'productSummary-onload'
              ##2.1.実際に全商品数を取得して callback
              ##    全商品数 -> <div id="pageListing"><strong>XX</strong>商品</div>

              page.evaluate (->
                total = document.querySelector('div#pageListing strong').innerHTML
                totalAmount = Number(total)
              ), (result)=>
                console.log "result: #{result}" if @debug?
                page.totalAmount = result
                @callback null, result

            when 'productList'
              ##3.在庫管理：リスト取得
              ##  TODO: 時々 失敗することがある。対策要！！！
              @route = 'productList-onload'
              page.open "https://sellercentral.amazon.co.jp/myi/search/ProductSummary"
            when 'productList-onload'
              ##3.1.在庫管理：まずは全商品数を取得
              ##    全商品数 -> <div id="pageListing"><strong>XX</strong>商品</div>
              ##

              page.evaluate (->
                total = document.querySelector('div#pageListing strong').innerHTML
                totalAmount = Number(total)
              ), (result)=>
                console.log "result: #{result}" if @debug?
                page.totalAmount = result
                page.pageNo = 1
                page.items = []
                @route = 'productList-loop'
                @trigger()
            when 'productList-loop'
              ###
              ##3.1.在庫管理：各アイテムの情報を取得。全商品数に満たない場合は次ページヘ移動していく
              ##  ページ当りの商品数を250とし(予め設定)、ページ数は計算して求める。
              ##  searchController.gotoPage(_P_)でページ移動が可能
              ##
              ##  追加の場合、まずは商品一覧にないか全検索し、なければ追加を実施する。
              ##  以下のようにして各商品の情報を取得
              ##    items = document.querySelectorAll('input[name^=price]')
              ##      <input name="price|FR-KP0J-MKU2|4774146293" value="2,849"
              ##  また、商品のステータスを以下のように取得
              ##    trs = document.querySelectorAll('tr[id|=sku]')
              ##  各tdは以下のような順番で格納されている
              ##    td[0] -> <td><input type="hidden" name="sku" value="XX-XXXX-XXXX">
              ##    td[1] -> <td><input type="checkbox"
              ##    td[2] -> <td><span...><a href="#" >変更</a><a href=...>▼</a>
              ##    td[3] -> <td class="alignleft">出品中</td>         ==> status
              ##    td[4] -> <td class="alignleft">KO-6HDJ-U0S5</td>  ==> sku
              ##    td[5] -> <td class="alignleft"><a href=...>        4881357018</a>
              ##      ==> asin
              ##    td[6] -> <td class="alignleft"><a href=...>独習C++ [Apr 01, 1999] シルト,ハーバート、 靖, 神林、 Schildt,Herbert; トップスタジオ</a></td>
              ##      ==> title
              ##    td[7] -> <td>2009/11/17 03:58:12</td>             ==> release
              ##    td[8] -> <td><span...><input name="inv|KO-6HDJ-U0S5|4881357018" value="0"...
              ##      ==> amount
              ##    td[9] -> <td>中古 – 可</td>                        ==> condition
              ##    td[10]-> <td><div...><span...><input name="price|KO-6HDJ-U0S5|4881357018" value="398"... ==>出品価格
              ##      ==> sellPrice
              ##    td[11]-> <td><div><a ...> <div calss="shippingCharge tiny"...> or <a >
              ##                出品価格が最低価格の場合は 価格情報なし
              ##      ==> lowPrice
              ##      ==> delPrice 
              ##          TODO: 出品価格=最低価格の場合 lowPrice,delPrice 共に -1 とする
              ##    td[12]-> <td>出品者</td>                           ==> delivery
              ###
              trs = []
              getTrs = ->
                tds = []
                trs = document.querySelectorAll('tr[id|=sku]')
                Array::map.call trs, (tr)->#tr.getAttribute('id')
                  tds = tr.querySelectorAll('td')
                  #Array::map.call tds, (td)-> td
                  obj = {}
                  hashTds = 3:'status', 4:'sku', 7:'release', 9:'condition', 12:'delivery'
                  hashAs = 5:'asin', 6:'title'
                  for td, i in tds
                    switch i
                      when 3, 4, 7, 9, 12
                        obj[hashTds[i]] = td.innerHTML
                      when 5, 6
                        obj[hashAs[i]] = td.querySelector('a').innerHTML.match(/[^\t\n]+/)[0]
                      when 8
                        obj.amount = Number(
                          if (input=td.querySelector('input'))?
                            input.value
                          else
                            td.innerHTML)
                      when 10
                        obj.sellPrice = Number(
                          if (input=td.querySelector('input'))?
                            input.value.replace ',', ''
                          else
                            td.querySelector('.yourPriceDiv').innerHTML.match(/\d+/g).join '')
                      when 11
                        obj.lowPrice = Number(td.querySelector('a')
                          .innerHTML.match(/\d+/g)?.join '') or -1
                        obj.delPrice = Number(td.querySelector('div[class="shippingCharge tiny"]')
                          ?.innerHTML.match(/\d+/g)?.join '') or -1
                  return obj

              # 在庫商品(すべての在庫商品)画面に遷移
              page.evaluate getTrs, (trs)=>
                page.items = page.items.concat trs
                console.log "trs: #{trs.length}, items: #{page.items.length}" if @debug?
                if page.items.length < page.totalAmount
                  ##  TODO: https://sellercentral.amazon.co.jp/myi/search/ProductSummary?searchPageOffset=__page__
                  ##        も使えそう
                  page.open "https://sellercentral.amazon.co.jp/myi/search/ProductSummary"+
                    "?searchPageOffset=#{++page.pageNo}#"
                  ###
                  # setGlobal asin
                  setGlobal page, '__page__', ++page.pageNo
                  page.evaluate -> 
                    # TODO: 余り綺麗ではないが、ボタン7個目が丁度次ページボタンに当たるため
                    #     当面このやり方とする
                    buttons = document.querySelectorAll('button')
                    buttons[6].click()  
                  ###
                else
                  @callback null, page.items

            when 'add-catalog'
              ###
              ##4.出品を追加
              ##4.1.商品を登録(出品商品のASINなどを入力)
              ##
              ##  https://sellercentral.amazon.co.jp/gp/ezdpc-gui/start.html/ref=im_addlisting_dnav_home_
              ##  form[name=itemSearchForm]
              ##  input#searchStringTextId
              ##    TODO: 本の場合はISBNで詳細が表示される。他の場合も調査要
              ##          例. 4774146293　(ISBN 実践JS)
              ##  document.itemSearchForm.submit() ???
              ##  上記はURLでは iframe を使用して下記カタログ検索画面を表示している。こちらを使用する！！
              ##  https://catalog-sc.amazon.co.jp/abis/syh/SCIdentify.amzn?_encoding=UTF8&ref_=im_addlisting_dnav_home_
              ###

              @route = 'add-catalog-onload'
              page.open "https://catalog-sc.amazon.co.jp/abis/syh/SCIdentify.amzn?_encoding=UTF8&ref_=im_addlisting_dnav_home_"
            when 'add-catalog-onload'
              ##4.1.2.form をフィルしてsubmit

              # setGlobal conf.amazon
              setGlobal page, '__asin__', @args.asin

              # form fill and submit
              @route = 'add-select'
              page.evaluate ->
                document.querySelector('input#searchStringTextId').value = __asin__
                document.querySelector("form[name='itemSearchForm']").submit()
            when 'add-select'
              ###
              ##4.2.商品を登録(検索結果 ISBNの場合　　注：商品名の場合は異なった動き)
              ##  内容はほぼ3.1に検索結果が追加された画面。POST結果により以下のURLにRedirectされている
              ##    https://catalog-sc.amazon.co.jp/abis/ItemSearch/Search
              ##  ##TODO: ISBNで絞りこまれているため、submitだけでOK???...
              ##   <button ... onclick="itemSelected('4774146293');">が必要だろう。 
              ##   →　必要！！　エラーメッセージのようなものが表示されるが気にしないこと！
              ##
              ##  form[name=itemSelectedForm]
              ##  itemSelected(__isbn_str__)
              ##    TODO:その後、必要があれば以下　→　必要！　実施
              ##  document.itemSelectedForm.submit() !!
              ###
              
              # setGlobal conf.amazon
              setGlobal page, '__asin__', @args.asin

              @route = 'add-fillsubmit'
              # form fill and submit
              page.evaluate ->
                itemSelected(__asin__)
                document.itemSelectedForm.submit()
            when 'add-fillsubmit'
              ###
              ##4.3.商品提供の情報を登録
              ##  具体的に出品情報を登録する。以下のURLにRedirectされている
              ##    https://catalog-sc.amazon.co.jp/abis/Display/ItemSelected
              ##    TODO: Form Dataとしては asin, marketplaceIDとなっている。
              ##          フォームデータだけ渡してこのページをダイレクトに表示できると思われる
              ##  入力項目は以下とする（必須項目は頭に*を付加）
              ##   * コンディション
              ##        id="offering_condition" value="Used|Acceptable" 中古 – 可
              ##          <select class="" id="offering_condition" name="offering_condition" >
              ##              <option value="">- 選択 -</option>
              ##              <option value="New|New"  > 新品</option>
              ##              <option value="Used|LikeNew"  > 中古 – ほぼ新品</option>
              ##              <option value="Used|VeryGood"  > 中古 – 非常に良い</option>
              ##              <option value="Used|Good"  > 中古 – 良い</option>
              ##              <option value="Used|Acceptable"  > 中古 – 可</option>
              ##              <option value="Collectible|LikeNew"  > コレクター商品 – ほぼ新品</option>
              ##              <option value="Collectible|VeryGood"  > コレクター商品 – 非常に良い</option>
              ##              <option value="Collectible|Good"  > コレクター商品 – 良い</option>
              ##              <option value="Collectible|Acceptable"  > コレクター商品 – 可</option>
              ##              </select>
              ##     コンディション説明
              ##        id="offering_condition_note" 
              ##          <textarea name="offering_condition_note" cols="40" rows="5" id="offering_condition_note"></textarea>
              ##   * 販売価格
              ##        id="our_price"
              ##          <input type="text" name="our_price" maxlength="50" size="6" value="" onchange="" id="our_price">
              ##   * 在庫
              ##        id="Offer_Inventory_Quantity"
              ##           <input type="text" name="Offer_Inventory_Quantity" maxlength="25" size="6" value="" onchange="return validateInteger(this, '\u5728\u5EAB\u306F\u6574\u6570\u3067\u3042\u308B\u5FC5\u8981\u304C\u3042\u308A\u307E\u3059\u3002') && validateIntRange(this, 0, 1000, '\u5728\u5EAB\u306F0\u304B\u30891000\u306E\u7BC4\u56F2\u306B\u3042\u308A\u307E\u305B\u3093\u3002')" id="Offer_Inventory_Quantity"></span>
              ##   TODO: 国内配送が4日から7日以内となっているので現時点では以下は入力しないこととする
              ##     商品の入荷予定日　ブックオフからの入荷日を2日として今日+2日で入力(YYYY/MM/DD)
              ##        id="Offer_Inventory_RestockDate" 
              ##          <input  type="text" size="10" name="Offer_Inventory_RestockDate" id="Offer_Inventory_RestockDate" value="" onchange="" />
              ##
              ##  form[name=productForm]
              ##
              ##  productTableController.buttonClicked('productTableSaveAndFinish')
              ##  document.productForm.submit() !!
              ###
              
              # setGlobal conf.amazon
              setGlobal page, '__item__', @args

              # form fill and submit
              page.evaluate ->
                #console.log "when 7: #{document.querySelector('#searchStringTextId').id}"
                #otherprice = document.querySelector("a[href$='condition=used']").parentNode.querySelector('span')
                #console.log "otherprice=#{otherprice}"
                document.querySelector('#offering_condition').value = \
                  if __item__.condition? then __item__.condition else "Used|Acceptable"
                document.querySelector('#offering_condition_note').value = \
                  if __item__.conditionNote? then __item__.conditionNote else \
                    "多少きず等ありますが使用には支障のないレベルです。"
                document.querySelector('#our_price').value = __item__.sellPrice
                document.querySelector('#Offer_Inventory_Quantity').value = \
                  if __item__.amount? then __item__.amount else 1
                productTableController.buttonClicked('productTableSaveAndFinish')
                document.productForm.submit()
              , (result)=>
                @route = 'add-complete'
            when 'add-complete'
              @callback null, status

            when 'update'
              ##5.更新：在庫管理からasinで検索して更新する
              @route = 'update-onload'
              page.open "https://sellercentral.amazon.co.jp/myi/search/ProductSummary"
            when 'update-onload'
              ##5.1.在庫管理：まずは全商品数を取得
              ##    全商品数 -> <div id="pageListing"><strong>XX</strong>商品</div>
              ##

              page.evaluate (->
                total = document.querySelector('div#pageListing strong').innerHTML
                totalAmount = Number(total)
              ), (result)=>
                console.log "result: #{result}" if @debug?
                page.totalAmount = result
                page.pageNo = 1
                page.itemLength = 0
                @route = 'update-loop'
                @trigger()
            when 'update-loop'
              ###
              ##5.2.在庫管理：引数 asin, marketplaceID から詳細画面表示に必要な sku を取得する
              ##
              ##  追加の場合、まずは商品一覧にないか全検索し、なければ追加を実施する。
              ##  各商品の詳細については3.在庫一覧を参照。
              ###
              trs = []
              getSku = ->
                tds = []
                trs = document.querySelectorAll('tr[id|=sku]')
                console.log "trs.length = #{trs.length}"
                for tr, i in trs
                  tds = tr.querySelectorAll('td')
                  asin = tds[5].querySelector('a').innerHTML.match(/[^\t\n]+/)[0]
                  if asin is __asin__
                    sku = tds[4].innerHTML
                    console.log "hit: sku = #{sku}"
                    return {sku: sku}
                return {length: trs.length}

              # setGlobal conf.amazon
              setGlobal page, '__asin__', @args.asin

              # 在庫商品(すべての在庫商品)画面に遷移
              page.evaluate getSku, (result)=>
                console.log "result: #{JSON.stringify(result)}" if @debug?
                if result.sku?
                  #5.1.2.商品提供情報の更新
                  # TODO: 詳細の編集は以下のURL (sku, asin, marketplaceID が必要)
                  #   https://catalog-sc.amazon.co.jp/abis/product/DisplayEditProduct?sku=FR-KP0J-MKU2&asin=4774146293&marketplaceID=A1VC38T7YXB528

                  @route = 'update-fillsubmit'
                  #page.open "https://catalog-sc.amazon.co.jp/abis/product/DisplayEditProduct"+ \
                  #  "?sku=#{result.sku}&asin=#{@args.asin}&marketplaceID=#{@args.marketplaceID}"
                  ##TODO: 厳密に更新は上記URLだが、condition更新不可のため、更新可能な再出品のURLを使用する
                  ##https://catalog-sc.amazon.co.jp/abis/edit/RelistProduct.amzn?sku=U5-HC02-5JVF&asin=4274067149&marketplaceID=A1VC38T7YXB528
                  page.open "https://catalog-sc.amazon.co.jp/abis/edit/RelistProduct.amzn"+ \
                    "?sku=#{result.sku}&asin=#{@args.asin}&marketplaceID=#{@args.marketplaceID}"
                else if (page.itemLength+=result.length) < page.totalAmount
                  ##  TODO: https://sellercentral.amazon.co.jp/myi/search/ProductSummary?searchPageOffset=__page__
                  ##        も使えそう
                  page.open "https://sellercentral.amazon.co.jp/myi/search/ProductSummary"+
                    "?searchPageOffset=#{++page.pageNo}#"
                else
                  #@callback new Error('asin not found')
                  @route = 'add-catalog'
                  @trigger()

            when 'update-fillsubmit'
              #5.3.商品提供情報の更新
              #5.3.2 具体的な値の追加と保存（更新）
              #  入力内容については3.3.の追加と同様。（画面も共有したような構成になっている）
              #
              #   * 販売価格
              #        id="our_price"
              #   * 在庫
              #        id="Offer_Inventory_Quantity"

              # setGlobal conf.amazon
              setGlobal page, '__item__', @args
                  
              # form fill and submit
              page.evaluate ->
                if __item__.condition?
                  document.querySelector('#offering_condition').value = __item__.condition
                if __item__.conditionNote?
                  document.querySelector('#offering_condition_note').value = \
                    __item__.conditionNote
                if __item__.sellPrice?
                  document.querySelector('#our_price').value = __item__.sellPrice
                if __item__.amount?
                  document.querySelector('#Offer_Inventory_Quantity').value = __item__.amount
                productTableController.buttonClicked('productTableSaveAndFinish')
                document.productForm.submit()
              , (result)=>
                @route = 'update-complete'
            when 'update-complete'
              @callback null, status

            when 'remove'
              ##TODO: 未完成：confirm画面が表示された後の、OKボタン押下の方法を調査要！！！
              ##6.削除：在庫管理からasinで検索して削除する
              @route = 'remove-onload'
              page.open "https://sellercentral.amazon.co.jp/myi/search/ProductSummary"
            when 'remove-onload'
              ##6.1.在庫管理：まずは全商品数を取得
              ##    全商品数 -> <div id="pageListing"><strong>XX</strong>商品</div>
              ##

              page.evaluate (->
                total = document.querySelector('div#pageListing strong').innerHTML
                totalAmount = Number(total)
              ), (result)=>
                console.log "result: #{result}" if @debug?
                page.totalAmount = result
                page.pageNo = 1
                page.itemLength = 0
                @route = 'remove-loop'
                @trigger()
            when 'remove-loop'
              ###
              ##6.2.在庫管理：引数 asin, marketplaceID から詳細画面表示に必要な sku を取得する
              ##
              ##  追加の場合、まずは商品一覧にないか全検索し、なければ追加を実施する。
              ##  各商品の詳細については3.在庫一覧を参照。
              ###
              trs = []
              getSku2 = ->
                tds = []
                trs = document.querySelectorAll('tr[id|=sku]')
                console.log "trs.length = #{trs.length}"
                for tr, i in trs
                  tds = tr.querySelectorAll('td')
                  asin = tds[5].querySelector('a').innerHTML.match(/[^\t\n]+/)[0]
                  if asin is __asin__
                    sku2 = tr.getAttribute('id').replace 'sku-',''
                    console.log "hit: sku2 = #{sku2}"
                    return {sku2: sku2}
                return {length: trs.length}

              # setGlobal conf.amazon
              setGlobal page, '__asin__', @args.asin

              # 在庫商品(すべての在庫商品)画面に遷移
              page.evaluate getSku2, (result)=>
                console.log "result: #{JSON.stringify(result)}" if @debug?
                if result.sku2?
                  #5.1.2.商品提供情報の更新
                  # TODO: 詳細の編集は以下のURL (sku, asin, marketplaceID が必要)
                  #   https://catalog-sc.amazon.co.jp/abis/product/DisplayEditProduct?sku=FR-KP0J-MKU2&asin=4774146293&marketplaceID=A1VC38T7YXB528

                  @route = 'remove-complete'
                  # setGlobal conf.amazon
                  setGlobal page, '__sku2__', result.sku2
                  page.evaluate ->
                    deleteSingleSku(__sku2__)
                  , (result)=>
                    @route = 'idle'
                    @trigger()
                else if (page.itemLength+=result.length) < page.totalAmount
                  ##  TODO: https://sellercentral.amazon.co.jp/myi/search/ProductSummary?searchPageOffset=__page__
                  ##        も使えそう
                  page.open "https://sellercentral.amazon.co.jp/myi/search/ProductSummary"+
                    "?searchPageOffset=#{++page.pageNo}#"
                else
                  @callback new Error('asin not found')

            when 'remove-complete'
              @callback null, status

            when 'signout'
              @route = 'signout-onload'
              @trigger()
            when 'signout-onload'
              @route = 'close'
              @trigger()
              @callback null
            when 'idle'
              console.log 'now idling...' if @debug?
              page.render "amaMan-#{@route}.png" if @debug?
                
              @callback null, null
            when 'close'
              @phantom.exit()
        
        cb null, @

###
        when 3
          #2.在庫管理(在庫一覧)
          #  TODO: 時々 複数の onLoadFinished が呼ばれる場合がある。解析要！！
          page.open "https://sellercentral.amazon.co.jp/myi/search/ProductSummary"
        when 4
          #2.1.在庫管理（在庫一覧）
          #  以下の情報を取得する。
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
          page.maketplaceID = page.evaluate ->
            document.querySelector('input[name=marketplaceID]').value
          
          # setGlobal asin
          setGlobal page, '__asin__', '4774146293'

          item = page.evaluate ->
            inputs = document.querySelectorAll('input[name^=price]')
            item = {}
            for input, i in inputs
              [price, sku, asin] = input.name.split('|')
              value = input.value
              if asin is __asin__
                item = { price: price, sku: sku, asin: asin, value: value }
            return item
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
          #setTimeout -> 
          #  page.render "amatest5.png"
          #  amaMan.trigger()
          #  return
          #, 1000
          
          
          ph.exit()
      return

    # amaMan start
    amaMan.trigger()

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