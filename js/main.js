$(document).ready(function(){

	var gallery = $('.grid').masonry({
		// options
		itemSelector: '.grid-item',
		columnWidth: '.grid-sizer',
		gutter: 20,
		percentPosition: true
	});

	gallery.imagesLoaded().progress( function() {
		gallery.masonry('layout');
	});

});