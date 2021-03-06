httpGet = require('./httpGet').httpGet

###
//
// pricecheckに関する細かな定義
// 
//  ・JAN(EAN)により、最大10個まで検索可能
//  
//  http://so-bank.jp/choice/?ean=9784876999767+%0D%0A9784839941239+%0D%0A9784401748693+%0D%0A9784120042201+%0D%0A9784860850999+%0D%0A9784776808121+%0D%0A9784046217585+%0D%0A9784336052117+%0D%0A9784490206937+%0D%0A9784829144916+%0D%0A
###
urlTop = 'http://so-bank.jp'
urlJan = '/choice/?ean='
urlSplit = '+%0D%0A'

strong = (self, result, key)->
  re = self.find('strong').text().match(/\d+/)
  result[key] = if (re) then Number(re[0]) else 0

###
// PriceCheck : JAN(最大10件)に対応するAmazon（PriceCheck）情報を取得
// input      : conf コンフィギュレーション
// input      : JANS 配列（最大10件）
// output : callback(err, genre) コールバック関数 genreはジャンル情報リスト(配列)
###
exports.getPCInfolist = (conf, JANS, callback) ->
  url = urlTop + urlJan
  # JANSをセット
  for JAN in JANS
    url = url + JAN + urlSplit
  #console.log "url: #{url}"
  
  # jQueryを利用してHTMLを取得する
  httpGet url, conf, (err, $) ->
    if err then return callback err
    #console.log $.html()
    # .searchResult : Array
    results = []
    $searchResult = $('.searchResult')
    $searchResult.each (index) ->
      self = $(this)
      #console.log "searchResult[#{index}] = #{self}"
      pcUrl = self.children().children().attr('href')
      asin = pcUrl.replace '/detail/?code=', ''
      result =
        JAN: JANS[index]
        asin: asin
        url: urlTop+pcUrl
      # ul.listStyle1
      $($($(self.children()[1]).children()).children()).each (index2) ->
        self = $(this)
        #console.log('ul[%d,%d] ',index, index2, self);
        switch index2
          when 0
            result.title = self.find('a').text()
          when 1
            result.author = self.text()
          when 2
            strong self, result, 'new'
          when 3
            strong self, result, 'old'
          when 4
            strong self, result, 'past'
          when 5
            strong self, result, 'diff'
          when 6
            strong self, result, 'rank'
      #console.log "results[#{index}] = #{JSON.stringify result, null, " "}"
      results[index] = result
    #console.log results
    callback null, results
exports.getList = exports.getPCInfolist

urlDetail = '/detail/?code='
exports.getDetail = (conf, asin, callback) ->
  url = urlTop + urlDetail + asin
  #console.log "url: #{url}"

  # jQueryを利用してHTMLを取得する
  httpGet url, conf, (err, $) ->
    if err then return callback err
    #console.log $.html()
    # #detail_txt
    result = {}
    $li = $('div#detail_txt li')
    $li.each (index)->
      self = $(this)
      #console.log index, self.text()
      switch index
        when 0
          result.release =
            if (re = self.text().match(/\d\d\d\d-\d\d-\d\d/))?
              re[0]
            else if (re = self.text().match(/\d\d\d\d-\d\d/))?
              re[0]
            else null
        when 1
          result.author = self.text().replace '作者：', ''
        when 2
          result.publish = self.text().replace 'メーカー：', ''
        when 3
          result.JAN = if (re=self.text().match(/\w+/g))? then re[1] else null
        when 4
          result.new = if (re=self.text().match(/\d+/))? then Number(re[0]) else 0
        when 5
          result.old = if (re=self.text().match(/\d+/))? then Number(re[0]) else 0
        when 6
          result.url = self.children().attr('href')
    #console.log result
    callback null, result
