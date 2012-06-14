apac = require './lib/apac'
conf = require './config'

JANS = ['9784338218023', '9784904336236']

apac.getApaclist conf.amazon, JANS, (err, items)->
  for item in items
    console.log JSON.stringify item, null, "  "
