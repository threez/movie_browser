
/* DROP DOWN FROM http://javascript-array.com/scripts/jquery_simple_drop_down_menu/ */

var timeout     = 250;
var closetimer	= 0;
var ddmenuitem  = 0;

function jsddm_open()
{	jsddm_canceltimer();
	jsddm_close();
	ddmenuitem = $(this).find('ul').eq(0).css('visibility', 'visible');}

function jsddm_close()
{	if(ddmenuitem) ddmenuitem.css('visibility', 'hidden');}

function jsddm_timer()
{	closetimer = window.setTimeout(jsddm_close, timeout);}

function jsddm_canceltimer()
{	if(closetimer)
	{	window.clearTimeout(closetimer);
		closetimer = null;}}

$(document).ready(function()
{	$('#menu > li').bind('mouseover', jsddm_open);
	$('#menu > li').bind('mouseout',  jsddm_timer);});

document.onclick = jsddm_close;

function mark(category, movie_id) {
	window.location.href = '/user/mark/' + category + '/' + movie_id;
}

function unmark(marker_id) {
	window.location.href = '/user/unmark/' + marker_id;
}
