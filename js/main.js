var gallery = null;
var pageOffset = '';
var isLoading = false;
var tierList = [0, 5.99, 19.99];
var inMobile = false;

function vimeoInit(target, callback) {
	// This is the URL of the video you want to load
	var videoUrl = target.attr('src');
	// This is the oEmbed endpoint for Vimeo (we're using JSON)
	// (Vimeo also supports oEmbed discovery. See the PHP example.)
	var endpoint = 'https://www.vimeo.com/api/oembed.json';
	// Put together the URL
	var url = endpoint + '?url=' + encodeURIComponent(videoUrl) + '&callback=' + callback + (inMobile?'':'&width=780&height=550');
	// This function puts the video on the page

    var js = document.createElement('script');
    js.setAttribute('type', 'text/javascript');
    js.setAttribute('src', url);
    document.getElementsByTagName('head').item(0).appendChild(js);

    var vimeoAPI = document.createElement('script');
    vimeoAPI.setAttribute('type', 'text/javascript');
    vimeoAPI.setAttribute('src', "https://player.vimeo.com/api/player.js");
    document.getElementsByTagName('head').item(0).appendChild(vimeoAPI);
}

function embedVideo(video) {
    document.getElementById('movie-container').innerHTML = unescape(video.html);

    var iframe = $('#movie-container iframe')[0];
    var player = new Vimeo.Player(iframe);

    player.on('play', function(d) {
        var currentTime = d.seconds;
        // ga('send', 'event', 'Mirror Video', 'Played the Index Video', "played:"+currentTime);
        // analytics.track('Played the Index Video',{
        //     type: 'played',
        //     videoTime: currentTime,
        // });
    });

    player.on('pause', function(d) {
        var currentTime = d.seconds;
        // ga('send', 'event', 'Mirror Video', 'Paused the Index Video', "paused:"+currentTime);
        // analytics.track('Paused the Index Video',{
        //     type: 'paused',
        //     videoTime: currentTime,
        // });
    });

    player.on('ended', function(d) {
        // analytics.track('Played the entire Magic Mirror index video');
        // ga('send', 'event', 'Mirror Video', 'Played the entire index video');
    });

    player.on('seeked', function(d) {
        var currentTime = d.seconds;
        // ga('send', 'event', 'Mirror Video', 'Seeked the Index Video', "seeked:"+currentTime);
        // analytics.track('Seeked the Index Video',{
        //     type: 'seeked',
        //     videoTime: currentTime,
        // });
    });
}

function twitterShare(link, text){
	// ga('send', 'event', 'Share', 'Twitter share clicked', window.location.href);
	// analytics.track('Twitter share clicked');
	var formattedText = encodeURI(text.replace(/\<br\>/g, "%0A"));
	window.open("https://twitter.com/intent/tweet?link="+link+"&original_referer="+link+"&text="+formattedText, "share", "width=640,height=443");
}

function wtf(){
	
}

function facebookShare(link, text){
	// ga('send', 'event', 'Share', 'Facebook share clicked', window.location.href);
	// analytics.track('Facebook share clicked');
	window.open("http://www.facebook.com/sharer/sharer.php?u="+link, "share", "width=640,height=443");
}

function slugify(text){
  return text.toString().toLowerCase()
    .replace(/\s+/g, '-')           // Replace spaces with -
    .replace(/[^\w\-]+/g, '')       // Remove all non-word chars
    .replace(/\-\-+/g, '-')         // Replace multiple - with single -
    .replace(/^-+/, '')             // Trim - from start of text
    .replace(/-+$/, '');            // Trim - from end of text
}

function getMenuString(deviceString){
	return deviceString.toUpperCase().replace(' ', '');
}

function createTemplateCard(link, extLink, images, title, description, profileUrl, authorDetail, price){
	var row = $('<div>').addClass('grid-item');
	var cover = (images&&images.length>0)?images[0].url:'';
	var priceElm = 'Free';

	if(price){
		var light = $('<span>').addClass('price-light-text');
		var dim = $('<span>').addClass('price-dim-text');
		priceElm = $('<span>').append(light).append(dim);
		$.each(tierList, function(index, t){
			if(price > t){
				light.html(new Array(index + 2).join( '$' ));
				dim.html(new Array(4 - (index + 1)).join( '$' ));
			}
		});
	}

	var el = document.createElement('a');
	el.href = extLink;

	var previewImageDiv = $('<div>').addClass('preview-image').appendTo(row);
	var previewLink = $('<a>').attr({'href': link, 'target': '_blank'}).appendTo(previewImageDiv);
	var previewImage = $('<img>').attr({'src': cover}).appendTo(previewLink);

	var infoSection = $('<div>').addClass('info').appendTo(row);

	var infoLeft = $('<div>').addClass('info-left').appendTo(infoSection);
	
	$('<div>').addClass('title').append($('<a>').attr({'href': link, 'target': '_blank'}).html(title)).appendTo(infoLeft);
	$('<div>').addClass('description').append($('<a>').attr({'href': link, 'target': '_blank'}).html(description)).appendTo(infoLeft);
	$('<div>').addClass('link').append($('<a>').attr({'href': link, 'target': '_blank'}).html(el.hostname)).appendTo(infoLeft);

	var authorSection = $('<div>').addClass('author-section').appendTo(infoLeft);

	$('<div>').addClass("profile-picture").append($('<img>').attr({src: profileUrl})).appendTo(authorSection);
	$('<div>').addClass("author-text").html(authorDetail).appendTo(authorSection);

	var infoRight = $('<div>').addClass('info-right').html(priceElm).appendTo(infoSection);
	if(price){
		infoRight.addClass('price');
	}else{
		infoRight.addClass('free');
	}

	return row;
}

function getTemplate(deviceType, offset, keyword){
	var container = $('#templateContainer');

	if(pageOffset != 'END'){
		isLoading = true;
		$('#imgLoader').show();

		$.ajax({
	        url: 'https://api.magicsketch.io/r/get_web_template?device='+deviceType+'&offset='+offset,
	        method: "GET",
	        dataType: "json",
	        complete: function(json){
	        	isLoading = false;
	        	$('#imgLoader').hide();
	        },
	        success: function(json){
	        	pageOffset = json.offset || 'END';

	        	if(json.records && json.records.length > 0){
	        		$.each(json.records, function(index, r){
	        			var card = new createTemplateCard('/template/'+slugify(r.fields["Name"]), r.fields["URL"], r.fields["Preview"], r.fields["Name"], '', '/images/profile.png', r.fields["Author"]+'<br/>iOS, MAC', r.fields["Price"]);
	        			gallery.append(card).masonry( 'appended', card);
	        		});

		            gallery.imagesLoaded().progress( function() {
						gallery.masonry('layout');
					});
	        	}

	        	if (pageOffset == 'END'){
	        		$('#footerSubmitButton').show();
	        	}

	        },
	        error: function(e){
	            
	        }
	    });
	}
}

function getParameterByName(name) {
	name = name.replace(/[\[]/, "\\[").replace(/[\]]/, "\\]");
	var regex = new RegExp("[\\?&]" + name + "=([^&#]*)"),
	results = regex.exec(location.search);
	return results === null ? null : decodeURIComponent(results[1].replace(/\+/g, " "));
}


$(document).ready(function(){
	var deviceType = getParameterByName("device") || '';

	getTemplate(deviceType, pageOffset, '');

	gallery = $('.grid').masonry({
		// options
		itemSelector: '.grid-item',
		columnWidth: '.grid-sizer',
		gutter: 20,
		percentPosition: true
	});

	$('[category="'+getMenuString(deviceType==''?'All':deviceType)+'"]').addClass('active');

	$('#navToggleButton').click(function(e){
		$('#navMenu').slideToggle(200);
	});

	$('.search-input').on('keypress', function(e){
        if (e.keyCode == 13) {
            var box = $(e.target);
            box.blur();

            $('.search-input').val(box.val());

            pageOffset = '';
            
            getTemplate(deviceType, pageOffset, box.val());
        }
    });

	$(window).scroll(function() {
		if($(window).scrollTop() + $(window).height() > $(document).height() - 100 && !isLoading) {
			getTemplate(deviceType, pageOffset, '');
		}
	});

	if($('.preview-section').length > 0){
		$('.preview-section').on('mouseenter', function(e){
			$('.social').addClass('visible');
		}).on('mouseleave', function(e){
			$('.social').removeClass('visible');
		});
	}

	if($('#movie-container').length > 0){
        vimeoInit($('#movie-container'), 'embedVideo');
    }

    if($(window).width() < 992){
		inMobile = true;
	}

});