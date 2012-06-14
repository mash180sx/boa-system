Ftp = require 'ftp'

exports.ftp = (filename, conf, callback) ->
  callback ?= ->
  host = if conf.firewall? then conf.firewall else conf.host
  auth = if conf.firewall? then "#{conf.user}@#{conf.host}" else conf.user
  pass = conf.pass

  # new FTP client
  connect = new Ftp host: host

  #console.log "ftp.connect.start #{host}"
  # FTP connect
  connect.connect()
  # connect listener 'connect'
  connect.on 'connect', ->
    # authentication
    connect.auth auth, pass, (err) ->
      if err
        #console.log 'auth error'
        return callback err

      # download filename
      connect.get filename, (err, stream) ->
        if err
          #console.log('get error');
          return callback err

        # os = fs.createWriteStream(filename);
        #os = process.stdout
        # stream listener 'success'
        stream.on 'success', ->
          # console.log('download success : ' + filename);
          connect.end()
        # stream listener 'error'
        .on 'error', (err) ->
          #console.log('ERROR during get(): ' + util.inspect(err));
          callback err

        callback null, stream