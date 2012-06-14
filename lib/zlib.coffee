zlib = require 'zlib'

rs = process.openStdin()
os = process.stdout
rs.pipe(zlib.createGunzip()).pipe(os)
