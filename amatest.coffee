amazon = require './lib/amazon'
conf = require './config'

JANS = ['4582200671847','9784416495087','4988003366773','4988104069276','9784391116977','9784167228033','9784276435827','9784863321892','9784840732673','4988008632835']

amazon.getAbstract conf.http, JANS[0], (err, result)->
  console.log result