// jsdomとjQueryのラッパー

//var jsdom = require('jsdom/lib/jsdom');
var cheerio = require('cheerio');
var httpget = require('../lib/httpGet');

// URLからリソースを読み込みjQueryを追加する
exports.getWithJquery = function(targetUrl, jquery_js, callback) {
    httpget.httpGet(targetUrl , function(err, body) {
        if (err) {
            if (callback) {
                callback(err);
            } else {
                throw err;
            }
        }
        $ = cheerio.load(body);
        window = $;
        if (callback) {
          callback(null, window, $);
        }
        /*
        var options = {};
        options.features = {};
        options.features.FetchExternalResources = false;
        options.features.ProcessExternalResources = false;
        var window = jsdom.jsdom(body, null, options).createWindow();
        jsdom.jQueryify(window, jquery_js, function(window, $) {
            // callbackを呼び出す
            if (callback) {
                callback(null, window, $);
            }
        });
        */
        
    });
}

