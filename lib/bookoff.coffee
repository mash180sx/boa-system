{httpGet} = require './httpGet'

###
//
// bookoffに関する細かな定義
//
//  bg=XXXX : ジャンル
//  st=u : 中古在庫あり
###
urlStock = '/display/L001,st=u'

###
// p=X : ページ番号(1は省略)
// &isAdult=y : アダルト認証OK
###
urlAdult = '&isAdult=y'

###
// Bookoff : トップページからジャンル毎の物件リストを取得
// input    : options  = {
//              minPrice: 取得する物件情報の最低価格を指定
//              }
// output : callback(err, genre) コールバック関数 genreはジャンル情報リスト(配列)
###
exports.getBOGenreList = (conf, callback)->
  
  # ブックオフTOPのURL
  urlTop = 'http://www.bookoffonline.co.jp/top/CSfTop.jsp'

  # ブックオフ 中古在庫ありのURL例
  # url = 'http://www.bookoffonline.co.jp/display/L001,st=u,bg=XXXX'
  genreUrl = "#{urlTop}#{urlStock},bg="
  # pr=[u]XXXX-YYYY : 新品[中古]価格絞り込み
  minPrice = conf.bookoff.minPrice
  urlPrice = if minPrice>0 then ",pr=#{minPrice}-" else ""
  # TODO: console.log('options.minPrice = %d, price = %s', options.minPrice, price);
  
  # jQueryを利用してHTMLを取得する
  httpGet urlTop, conf.http, (err, $)->
    if err then return callback err
    # ジャンルリスト取得
    genre = []
    # Topページの id=navi02〜navi06 にジャンルリストが記述されている
    index = 0
    count = 0
    arr = [2..6]
    len = arr.length
    for item in arr
      # category.primary 親カテゴリ名の取得
      $a = $('#navi0'+item+' a')
      href = $a.attr('href')
      primary = $a.text()
      ###
        // *
        // *url 設定 TODO:
        // *
       ###
      #console.log "href = #{href}"
      cb = (err, $2)->
        #if err then return # callback err
        unless $2
          count++
          console.log "$2 is undefined : #{count}/#{len} error: #{err}"
          if count is len
            console.log "#{count}: #{genre}"
            callback null, genre
          else return
        arr2 = $2('ul.list01 li a').toArray()
        len2 = arr2.length
        #console.log arr2
        for self, i in arr2
          href = $2(self).attr('href')
          id = String(href.match(/bg=\d+/)).replace 'bg=',''
          secondary = $2(self).text()
          _genre = {id: id, category: {primary: primary, secondary: secondary}, url: href}
          #console.log "%d : %j", index, _genre
          genre.push _genre
          index++
          #console.log "#{count+1}/#{len}: #{item}, #{i+1}/#{len2}"
          if count+1 is len and i+1 is len2
            #console.log "#{count+1}: #{item}, #{i+1}: #{genre}"
            callback null, genre
        count++
        return
      httpGet href, conf.http, cb
    return

###
// Bookoff : genruで与えられるジャンル番号から在庫リスト情報(Max 20件の物件データ)を取得する
// input  : conf = { bookoff: {
//            minPrice: 取得する物件情報の最低価格を指定
//            stock: true ならジャンルのtotal件数と在庫のチェックのみ実施
//          }}
// input  : genru ジャンル番号
// input  : page ページ番号を指定
// output : callback(err, stock) コールバック関数 stockは在庫リスト情報
###
exports.getBOStockList = (conf, genru, page, callback)->
  url = "http://www.bookoffonline.co.jp/display/L001,st=u,bg=#{genru}"
  # TODO: console.log('url = %s', url);
  minPrice = conf.bookoff.minPrice
  urlPrice = if minPrice then ",pr=#{minPrice}-" else ''
  stockflag = conf.bookoff.stock
  # p=X : ページ番号(1は省略)
  urlPage = if page && page>1 then ",p=#{page}" else ''
  url = url + urlPrice + urlAdult + urlPage
  #console.log "url = #{url}"
  stock = {}
  httpGet url, conf.http, (err, $)->
    if err then return callback err
    #console.log $('#resList').text()
    unless $('#resList').text()
      console.log "検索結果 0, #{url} #{$.html()}"
      stock.total = 0
      return callback null, stock
    re = $('#resList .numbers').text().match(/\d+/g)
    #console.log 'genre total ', re
    stock.total = Number re[2]
    # 20件のデータ取得
    stock.list = []
    $('.list_group').each (index)->
      list = {}
      list.sku = $(this).find('.cb').attr('value').slice(1)
      unless stockflag
        list.title = $(this).find('.itemttl a').text()
        list.author = $(this).find('.author').text()
        list.price = {}
        $(this).find('tr').each (index2)->
          switch $(this).find('th').text()
            when '定価'
              list.price.new = String($(this).find('td').text().replace(',','').match(/￥\d+/)).replace('￥','')
            when '中古価格'
              list.price.old = String($(this).find('td').text().replace(',','').match(/￥\d+/)).replace('￥','')
          list.amount = 1   # TODO: 取り敢えず在庫１として登録
          ###
          // TODO: JANを取得する
          //
          //_getItemDetail(list.sku, function(err, detail) {
          //  if(err) return callback(err);
          //  list.JAN = detail.JAN;
          //});
          //
          ###
        # TODO: console.log('%d : %j', index, list);
      stock.list.push list
    callback null, stock


_getItemDetail = (sku, conf, callback)->
  # console.log('_getItemDetail.conf ', conf);
  url = "http://www.bookoffonline.co.jp/old/#{sku}#{adult}"
  httpGet url, conf.http, (err, $)->
    if err then return callback err
    detail = {}
    detail.sku = sku
    detail.title = $('#ttl_det').text()
    detail.author = $('#ttl_nam a').text()
    detail.type = $('.type').text().trim()
    detail.price = {}
    $('#spec_table tr').each (index)->
      # TODO: console.log(index+' : '+$(this).find('th').text());
      switch $(this).find('th').text()
        when '定価'
          detail.price["new"] = String($(this).find('td').text().replace(',','').match(/￥\d+/)).replace('￥','')
        when '発送時期'
          detail.send = $(this).find('td').text()
    detail.price.old = String($('.oldprice').text().replace(',','').match(/￥\d+/)).replace('￥','')
    $('.infotxt tr').each (index)->
      # TODO: console.log($(this).find('td').text());
      switch $(this).find('th').text()
        when '販売会社／発売会社'
          detail.publisher = $(this).find('td').text().trim()
        when '発売年月日'
          detail.create = $(this).find('td').text().trim()
        when 'JAN'
          detail.JAN = $(this).find('td').text().trim()
    # TODO: console.log('nosotck : '+$('.nosotck').text());
    if $('.nosotck').text()
      detail.send = $('.nosotck').text().trim()
      detail.amount = 0
    else
      detail.amount = 1
    callback null, detail


exports.getBOItemDetail = (sku, conf, callback)->
  _getItemDetail sku, conf, callback
