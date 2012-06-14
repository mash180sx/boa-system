{EventEmitter} = require 'events'

class AmazonManager extends EventEmitter
  api: (method, args=[], callback=->) ->
    if @methods[method]?   # exists method
      @args = if typeof args isnt "function" then args
      @callback = callback = if typeof args is "function" then args else callback
      console.log "calling api ('#{method}', [#{JSON.stringify(args)}], #{callback})"
      @methods[method]()
    else    # not exists method
      callback 999, new Error('No such method')
    
  constructor: (options={}, cb=->) ->
    if typeof options is "function" then cb = options
    # options.proxy = {proxy:proxy, port:port}
    if options.proxy? then @proxy = options.proxy
    @methods =
      # サインインして一覧取得
      # TODO: 自動サインアウト
      'signin': (callback) =>
        @route = 'signin'
        @trigger()
      
      # 更新
      'update': (callback) =>
        callback err, result
      
      # 出品停止
      'stop': (callback) =>
        callback err, result
      
      # 出品再開
      'resale': (callback) =>
        callback err, result
      
      # 追加
      'add': (callback) =>
        callback err, result
      
      # サインアウト
      'signout': (callback) =>
        @route = 'signout'
        @trigger()
      
    # phatom用ルーティング定義
    @routes = [
      'signin'
      'signin-onload'
      'signin-complete'
      'productSummary'
      'productSummary-onload'
      'update'
      'update-onload'
      'resale'
      'resale-onload'
      'add-catalog'
      'add-catalog-onload'
      'add-select'
      'add-fillsubmit'
      'signout'
      'signout-onload'
    ]
    
    @trigger = (status='internal') =>
      console.log "emit '#{status}'   ('#{@route}')"
      @emit 'route', status
    
    @on 'route', (status)=>
      console.log "on 'route', ('#{status}')   : '#{@route}'"
      switch @route
        when 'signin'
          # 1.出品用アカウント サインイン画面
          @route = 'signin-onload'
          @trigger()
        when 'signin-onload'
          # 1.出品用アカウント サインイン画面
          @route = 'idle'
          @trigger()
        when 'signout'
          @route = 'signout-onload'
          @trigger()
        when 'signout-onload'
          @route = 'close'
          @trigger()
        when 'idle'
          console.log 'now idling...'
          @callback null, null
        when 'close'
          console.log "phantom.exit()"
          @callback null, null
          #@phantom.exit()
        
    cb null, @

conf = require './config'

amaMan = new AmazonManager (err, am) ->
  am.api 'signin', conf.amazon, (err, res) ->
    console.log 'signin complete'
    am.api 'signout', (err, res) ->
      console.log 'signout complete'
