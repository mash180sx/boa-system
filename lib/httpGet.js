var request = require('request');
var cheerio = require('cheerio');
var url = require('url');
var Iconv = null;

exports.httpGet = function(targetUrl, conf, callback) {
  if (conf.iconv!==false) {
    Iconv = require('iconv').Iconv;
  }
  var opts = {
      url: targetUrl,
      method: 'GET',
      encoding: null
  };
  //console.log('httpGet.conf', conf);
  var parse = url.parse(targetUrl);
  var req = (parse.protocol.match(/https/) ? 'https' : 'http');
  if(conf.proxy) {
    opts.proxy = 'http://'+conf.proxy+':'+conf.port;
  }
  //console.log(opts);
  request(opts, function(err, res, body) {
    if(err||res.statusCode!=200) return callback(err||res.statusCode);

    if(conf.iconv!==false) {
      var charset = null;
      var re = null;
      var content_type = res.headers['content-type'];
      if (content_type) {
        re = content_type.match(/\bcharset=([\w\-]+)\b/i);
        if (re) charset = re[1];
      }
      if (!charset) {
        var bin = body.toString('binary');
        re = bin.match(/<meta\b[^>]*charset=([\w\-]+)/i);
        if (re) {
          charset = re[1];
        } else {
          charset = 'UTF-8';
        }
      }
      
      //TODO:console.log(charset);
      switch (charset) {
      case 'ASCII':
      case 'UTF-8':
        body = body.toString(charset);
        break;
      default:
        var iconv = new Iconv(charset, 'UTF-8');
        var body = iconv.convert(body);
      }
    }
    $ = cheerio.load(body);
    callback(null, $);
  });
};

