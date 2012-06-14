var Sync = require('sync');
var request = require('request');
var cheerio = require('cheerio');
var url = require('url');
var Iconv = null;

var httpGet = exports.httpGet = function(targetUrl, conf, headers, callback) {
  if (conf.iconv!==false) {
    Iconv = require('iconv-jp').Iconv;
  }
  var opts = {
      url: targetUrl,
      method: 'GET',
      encoding: null,
      headers: headers
  };
  //console.log('httpGet.conf', conf);
  var parse = url.parse(targetUrl);
  var req = (parse.protocol.match(/https/) ? 'https' : 'http');
  if(conf.proxy) {
    opts.proxy = 'http://'+conf.proxy+':'+conf.port;
  }
  //console.log(opts);
  request(opts, function(err, res, body) {
    //console.log(err);
    if(err&&res.statusCode!=200) return callback(err);

    callback(null, {res: res, body: body});
  });
};

Sync(function() {
  var conf = require('./config');
  var amaUrl = 'https://sellercentral.amazon.co.jp/gp/homepage.html';
  var tstUrl = 'http://www.google.com/';
  var headers = {};//{'User-Agent':'Mozilla/5.0 (Windows NT 5.1) AppleWebKit/536.5 (KHTML, like Gecko) Chrome/19.0.1084.52 Safari/536.5'};

  var result = httpGet.sync(null, amaUrl, conf.http, headers);
  console.log('statusCode : ', result.res.statusCode);
  console.log('headers    : ', result.res.headers);
  //console.log('body       : ', result.body.toString('UTF-8'));
  
  var $ = cheerio.load(result.body.toString('UTF-8'));
  //console.log($.html());
  //Sync.sleep(1000);
  //console.log($);
  $('input').each(function(index) {
    console.log(index, $(this).attr('type'), $(this).attr('name'), $(this).attr('value'));
  });
  //$(':text').each(function(index) {
  //  console.log(index, this.name, this.value);
  //});
  //$('password').each(function(index) {
  //  console.log(index, this.name, this.value);
  //});
  
  var body = {
    destination:'https://sellercentral.amazon.co.jp/gp/homepage.html?ie=UTF8&%2AVersion%2A=1&%2Aentries%2A=0',
    action:'sign-in',
    pipeline:'seamless',
    marketplaceID:'XXXXXXXXXXXXXX',
    email:'XXX@XXXX.XXX',
    password:'XXXXXXXXXX',
    x:179,
    y:17,
    ue_back:1
  };
  
});