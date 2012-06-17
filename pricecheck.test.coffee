pc = require './lib/pricecheck'
conf = require './config'

# ////////// pricecheck search //////////
example = '9784876999767+%0D%0A9784839941239+%0D%0A9784401748693+%0D%0A9784120042201+%0D%0A9784860850999+%0D%0A9784776808121+%0D%0A9784046217585+%0D%0A9784336052117+%0D%0A9784490206937+%0D%0A9784829144916'
JANS = example.split '+%0D%0A'
console.log JANS
pc.getPCInfolist conf, JANS, (err, res)->
  console.log res
