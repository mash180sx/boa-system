// My SocketStream app

var http = require('http');
var ss = require('socketstream');

var db = require('./lib/db');
var conf = require('./config');

// Define a single-page client
ss.client.define('main', {
  view: 'app.html',
  css:  ['libs', 'app.styl'],
  code: ['libs', 'app'],
  tmpl: '*'
});

// Serve this client on the root URL
ss.http.route('/', function(req, res){
  res.serveClient('main');
})

// Code Formatters
ss.client.formatters.add(require('ss-stylus'));

// Use server-side compiled Hogan (Mustache) templates. Others engines available
ss.client.templateEngine.use(require('ss-hogan'));

// Minimize and pack assets if you type: SS_ENV=production node app.js
if (ss.env == 'production') ss.client.packAssets();

// Start web server
var server = http.Server(ss.http.middleware);
server.listen(3000);

// Open db
db.open(conf.db, function(err, client) {
  if(err) throw err;
  
  ss.api.add('Categories', client.collection('categories'));
  ss.api.add('Commodities', client.collection('commodities'));
  
});

// Start SocketStream
ss.start(server);