// Server-side Code

// Define actions which can be called from the client using ss.rpc('demo.ACTIONNAME', param1, param2...)
exports.actions = function(req, res, ss) {

  // Example of pre-loading sessions into req.session using internal middleware
  req.use('session');

  // Uncomment line below to use the middleware defined in server/middleware/example
  //req.use('example.authenticated')

  return {

    // model.categories(category_id)
    categories: function(category_id) {
      // get session category_id
      //console.log('category_id:', category_id);
      if(!category_id) {
        ss.Categories.findOne(function(err, doc) {
          if(err) return res(false);
          category_id = doc._id;
        });
      }
      ss.Categories.find().toArray(function(err, docs) {
        if(err) return res(false);
        for(var i=0, l=docs.length; i<l; i++) {
          //console.log(docs[i]._id, category_id, (String(docs[i]._id)==String(category_id)));
          docs[i].selected = (String(docs[i]._id)==String(category_id)) ? 'selected' : '';
        }
        //console.log('categories ', docs);
        ss.publish.all('categories', docs, category_id);
        return res(true);
      });
    },

    // model.commodities(category_id[, queries, limit, skip])
    commodities: function(category_id, _queries, _limit, _skip) {
      console.log('category_id', category_id);
      ss.Categories.find().each(function(err, doc) {
        if(err) return res(false);
        //console.log('category',doc);
        if(doc) {
          //console.log(doc._id, category_id, (String(doc._id)==String(category_id)));
          if(String(doc._id)==String(category_id)) {
            console.log(doc.name);
            var queries = (_queries) ? _queries : {};
            queries['category.primary'] = doc.name;
            // 在庫あり＆pricecheckあり
            queries.amount = 1;
            queries.pricecheck = {$exists:true};
            var options = {};
            options.limit = (_limit) ? _limit : 100;
            options.skip = (_skip) ? _skip : 0;
            options.sort = {'pricecheck.old':-1};
            console.log(queries, options);
            ss.Commodities.find(queries, {}, options).toArray(function(err, docs) {
              if(err) return res(false);
              
              //console.log('commodities:', docs);
              ss.publish.all('commodities', docs);
              return res(true);
            });
          }
        }
      });
      return res(true);
    }
    
  };

};