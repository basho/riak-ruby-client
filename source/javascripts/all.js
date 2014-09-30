//= require_tree .

jQuery(function($){
  var tocContainer = $('#toc')

  tocContainer.toc({
    container: '#yielded',
    smoothScrolling: false,
    highlightOnScroll: false
  });
});
