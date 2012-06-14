{ftp} = require './lib/ftp'

conf = require './config'

ftp conf.seed, conf.ftp, (err, stream)->
  os = process.stdout
  stream.pipe os
