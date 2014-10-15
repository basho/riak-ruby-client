//= require_tree .

jQuery(function($){
  var tocContainer = $('#toc')

  tocContainer.toc({
    container: '#yielded',
    smoothScrolling: false,
    highlightOnScroll: false,
    selectors: 'h1,h2,h3,h4,h5,h6'
  });
});
