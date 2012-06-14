var httpGet = require('./httpGet').httpGet;

//
// pricecheckに関する細かな定義
// 
//  ・JAN(EAN)により、最大10個まで検索可能
//  
//  http://so-bank.jp/choice/?ean=9784876999767+%0D%0A9784839941239+%0D%0A9784401748693+%0D%0A9784120042201+%0D%0A9784860850999+%0D%0A9784776808121+%0D%0A9784046217585+%0D%0A9784336052117+%0D%0A9784490206937+%0D%0A9784829144916+%0D%0A
var urlTop = 'http://so-bank.jp';
var urlJan = '/choice/?ean=';
var urlSplit = '+%0D%0A';

// PriceCheck : JAN(最大10件)に対応するAmazon（PriceCheck）情報を取得
// input      : conf コンフィギュレーション
// input      : JANS 配列（最大10件）
// output : callback(err, genre) コールバック関数 genreはジャンル情報リスト(配列)
exports.getPCInfolist = function(conf, JANS, callback) {
  var url = urlTop + urlJan;
  // JANSをセット
  for(var i=0, l=JANS.length; i<l; i++) {
    url = url + JANS[i] + urlSplit;
  }
  
  // jQueryを利用してHTMLを取得する
  httpGet(url, conf.http, function(err, $) {
    if(err) return callback(err);
    // .searchResult : Array
    var results = [];
    var $searchResult = $('.searchResult');
    $searchResult.each(function(index) {
      var self = $(this);
      //console.log('searchResult[%d] ', index, self);
      var pcUrl = $('.searchResult_img a', self).attr('href');
      var asin = pcUrl.replace('/detail/?code=','');
      var result = {
        JAN: JANS[index],
        asin: asin,
        url: urlTop+pcUrl
      };
      // ul.listStyle1
      $($($(self.children()[1]).children()).children()).each(function(index2) {
        var self = $(this);
        //console.log('ul[%d,%d] ',index, index2, self);
        switch(index2) {
        case 0:
          result.title = self.find('a').text();
          break;
        case 1:
          result.author = self.text();
          break;
        case 2:
          var re = self.find('strong').text().match(/\d+/);
          result.new = (re) ? Number(re[0]) : '-';
          break;
        case 3:
          var re = self.find('strong').text().match(/\d+/);
          result.old = (re) ? Number(re[0]) : '-';
          break;
        case 4:
          var re = self.find('strong').text().match(/\d+/);
          result.past = (re) ? Number(re[0]) : '-';
          break;
        case 5:
          var re = self.find('strong').text().match(/\d+/);
          result.diff = (re) ? Number(re[0]) : '-';
          break;
        case 6:
          var re = self.find('strong').text().match(/\d+/);
          result.lank = (re) ? Number(re[0]) : '-';
          break;
        }
      });
      results[index] = result;
    });
    callback(null, results);
  });
};
