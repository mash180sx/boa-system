httpGet = require('./httpGet').httpGet

###
//
//  Amazon から asin により詳細情報取得
// 
//  
//  http://www.amazon.co.jp/dp/B00005GOBJ
###
urlTop = 'http://www.amazon.co.jp'
urlDetail = '/dp/'

exports.getDetail = (conf, asin, callback) ->
  url = urlTop + urlDetail + asin
  console.log "url: #{url}"

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
          result.release = self.text().match(/\d\d\d\d-\d\d-\d\d/)[0]
        when 1
          result.author = self.text().replace '作者：', ''
        when 2
          result.publish = self.text().replace 'メーカー：', ''
        when 3
          result.JAN = self.text().match(/\w+/g)[1]
        when 4
          result.new = Number self.text().match(/\d+/)[0]
        when 5
          result.old = Number self.text().match(/\d+/)[0]
        when 6
          result.url = self.children().attr('href')
    #console.log result
    callback null, result
