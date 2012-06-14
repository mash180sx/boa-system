// Client Code

console.log('App Loaded');

// pub/sub definition
ss.event.on('categories', function(docs, category_id) {
  //console.log(docs, category_id);
  ss.rpc('model.commodities', category_id);
  var html = ss.tmpl.categories.render({
    categories: docs
  });
  $('#side-pane *').remove();
  return $(html).appendTo('#side-pane');
});

$('#side-pane').on('mousedown', '.category', function(evt) {
  var _id = $('.display', $(this)).attr('_id');
  ss.rpc('model.categories', _id);
});

ss.event.on('commodities', function(docs) {
  //console.log(docs);
  var html = ss.tmpl.commodities.render({
    commodities: docs
  });
  $('#main-pane *').remove();
  var ret = $(html).appendTo('#main-pane');
  $('table').ready(function() {
    $('table').tablesorter();
  });
  return ret;
});

ss.rpc('model.categories');

