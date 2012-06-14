// Generated by CoffeeScript 1.3.1
(function() {
  var Browser, amaOpUrl, browser, conf, idx;

  Browser = require("zombie");

  conf = require("./config");

  browser = new Browser({
    debug: true,
    waitFor: 5000
  });

  if (conf.http.proxy) {
    browser.proxy = "http://" + conf.http.proxy + ":" + conf.http.port;
  }

  amaOpUrl = "https://sellercentral.amazon.co.jp/myi/search/ProductSummary";

  browser.on('error', function(err) {
    return browser.log("error: ", err);
  });

  idx = 0;

  browser.on('loaded', function(brw) {
    return browser.log("browser.on[" + (++idx) + "]:" + browser.location);
  });

  browser.visit(amaOpUrl, function(err, brw, status) {
    var document, window;
    browser.log("window: ", window = brw.window);
    browser.log("document: ", document = window.document);
    return browser.log("browser.visit: " + (browser.html()));
  });

  browser.wait(5 * 1000, function() {
    browser.log("browser.wait: " + (browser.html()));
  });

  /*
  browser.wait ()->
      console.log "The.page:#{browser.html()}"
      # サインイン画面になるのでフォーム入力
      browser.fill('#email', conf.amazon.email)
      .fill('#password', conf.amazon.password)
      browser.wait(
        ()-> browser.document.signin.submit(),
        ()-> console.log "confirm.page:#{browser.html()}")
      return
  
  # 出品アカウント サインイン
  #https://www.amazon.co.jp/ap/signin?_encoding=UTF8&openid.assoc_handle=jpflex&openid.claimed_id=http%3A%2F%2Fspecs.openid.net%2Fauth%2F2.0%2Fidentifier_select&openid.identity=http%3A%2F%2Fspecs.openid.net%2Fauth%2F2.0%2Fidentifier_select&openid.mode=checkid_setup&openid.ns=http%3A%2F%2Fspecs.openid.net%2Fauth%2F2.0&openid.ns.pape=http%3A%2F%2Fspecs.openid.net%2Fextensions%2Fpape%2F1.0&openid.pape.max_auth_age=900&openid.return_to=https%3A%2F%2Fwww.amazon.co.jp%2Fgp%2Fseller-account%2Fmanagement%2Fyour-account.html%3Fie%3DUTF8%26ref_%3Dya__1
  
  # 在庫管理
  #https://sellercentral.amazon.co.jp/myi/search/ItemSummary.amzn?_encoding=UTF8&ref_=im_invmgr_dnav_home_
  #https://sellercentral.amazon.co.jp/myi/search/ItemSummary.amzn?_encoding=UTF8&ref_=im_invmgr_mmap_home
  
  # 商品詳細
  #https://catalog-sc.amazon.co.jp/abis/product/DisplayEditProduct?sku=JW-GF8T-H5AE&asin=B000J878BW&marketplaceID=A1VC38T7YXB528
  #https://sellercentral.amazon.co.jp/myi/search/ItemSummary.amzn?_encoding=UTF8&ref_=im_invmgr_mmap_home
  */


}).call(this);
