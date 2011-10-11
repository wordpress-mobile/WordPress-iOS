var jq = jQuery;

var Reader2 = {
  per_page: 10,
  page_num: 1,
  page_data: false,
  filter: 'no_p2',
  request: false,
  in_subs_list:true,
  pageYOffset: 0,
  last_selected_item: {},
  active_tab: null,
  list_item_template : "<div id='post-{{blog_id}}-{{post_id}}' class='subs-item' ontouchstart='return true' onclick=''>" +
	"<article class='subs-item-main'>" +
	"<header>" +
	"<hgroup>" +
		"<div class='meta'>" +
			"<span class='info'>" +
				"<span class='comments'>{{comment_count}}</span>" +
				"<span class='ago'>{{ago}}</span>" +
			"</span>" +
			"<h2 class='blog public'>" +
				"<img class='avatar' src='{{author_avatar}}' alt='' height='16' width='16' />" +
				"<span class='blog-title'>{{{blog}}}</span>" +
			"</h2>" +
		"</div>" +
		"<h1 class='title'>{{{title}}}</h1>" +
	"</hgroup>" +
	"</header>" +
	"<div class='excerpt'>{{{excerpt}}}</div>" +
	"</article>" +
	"</div>",
  
  pingStatsEndpoint: function (stat_name) {
	  jq.get("/wp-admin/admin-ajax.php", {
		  'action': 'wpcom_load_mobile', 
		  'template': 'stats',
		  'stats_name' : stat_name,
		  'screen_width' : window.screen.availWidth
	  });
  },

  init: function( ) {
    this.per_page = ( jq.query.get('per_page') ) ? jq.query.get('per_page') : this.per_page;
    this.page_num = ( jq.query.get('page_num') ) ? jq.query.get('page_num') : this.page_num;
    this.filter = ( jq.query.get('filter') ) ? jq.query.get('filter') : this.filter;

    //pings the Stats endpoint. note: this ping is not bumped when called inside one of our apps.
    if(  Reader2.active_tab == 'subs' ) {
    	this.pingStatsEndpoint('startup_stats');
    } else {
    	// The user started the Reader2 on the FP page.
    	this.pingStatsEndpoint('freshly');
    }
        
	//set the value of the filter if the cookie exists
	if ( jq.cookie( 'wpcom-mobile-reader-filter' ) != null ) {
		jq( '#filter-name' ).text( jq( '#filter_select option:selected' ).text() );
	}
	
	// Posts filter logic
	jq('#filter_select').live('change', function() {
		Reader2.page_num = 1;
		Reader2.filter = jq( '#filter_select' ).val();
		jq( '#filter-name' ).text( jq( '#filter_select option:selected' ).text() );
		jq('#subscriptions').html('');
		jq( '#loader' ).fadeToggle();
		jq.cookie('wpcom-mobile-reader-filter', Reader2.filter, { expires: 365 });
	    Reader2.load(false, function() {
	    	jq( '#loader' ).fadeToggle();
	        Reader2.render();
	        //preload the 2nd page of content
	        Reader2.load(true, function() {
	            Reader2.render();
	          } );
	    } );		
	}); 

    // Check for scrolling and fire this.load() when hitting then end of the page.
    jq( window ).scroll( this.onScroll );
	jq( 'body' ).attr( 'class', 'list' );    
	if(  Reader2.active_tab == 'subs' ) {
    	//load the page using ajax
	    jq( '#loader' ).fadeToggle();
	    Reader2.load(false, function() {
	    	jq( '#loader' ).fadeToggle();
	        Reader2.render();
	        //preload the 2nd page of content
	        Reader2.load(true, function() {
	            Reader2.render();
	          } );
	    } );
	}
  },
  
  load: function(show_loading_indicator, callback ) {
    if ( ( typeof this.request == 'object' ) && ( this.request !== null ) ) {
      return;
    }

    if(show_loading_indicator === true) {
    	jq( '#subscriptions' ).append( '<div id="loading-more">Wait, there\'s more...</div>' );
    }
    
	if ( jq.cookie( 'wpcom-mobile-reader-filter' ) != null ) {
		this.filter = jq.cookie( 'wpcom-mobile-reader-filter' );
	}

    this.request = jq.getJSON( '/wp-admin/admin-ajax.php', { 
      'action': 'wpcom_load_mobile', 
      'template': 'subscriptions',
      'v': 2,
      'per_page': this.per_page,
      'page_num': this.page_num,
	  'filter': this.filter,
      'screen_width' : window.screen.availWidth
    },
    function( result ) {
      jq( '#loading-more' ).remove();
      Reader2.request = null;
      Reader2.page_data = result;
	  if ( result.length < 1 ) {
	    jq( '#subscriptions' ).append( '<p class="noblogs">Nothing to read! Why not <a href="/#!/following/edit/">follow some blogs</a> or have a look at <a class="load-tab" rel="fresh" href="http://wordpress.com/reader/mobile/freshly-pressed">Freshly Pressed</a>?</p>' );
	  }
      if ( typeof callback == 'function' ) callback.call( this );
    })
  //  .success(function() { console.log("second success"); })
    .error(function() { jq( '#loading-more' ).remove();  Reader2.request = null; /*console.log("error");*/ });
  
  this.page_num++;
  },
  
  onScroll: function() {
    if ( Reader2.active_tab === 'subs' && Reader2.in_subs_list && Reader2.page_num && jq( window ).scrollTop() + jq( window ).height() >= jq( document ).height() - ( jq( window ).height() ) ) {
	  if ( Reader2.page_data.length )
        Reader2.render();
      else {
        Reader2.load(true, function() {
          Reader2.render();
        } );
      }
    }
  },

  /*
  showSubscriptions: function() {
    jq( '#article' ).hide();
    jq( '#subscriptions' ).show();
    jq( '#reader-tabs').show();
	jq('html, body').animate({ scrollTop: this.pageYOffset }, 1 );
	jq( 'body' ).attr( 'class', 'list' );
    this.in_subs_list = true;
  },
*/
  /* get the permalink of the current article loaded in the detail view. Used by the mobile apps */
  get_article_permalink : function () {
	  if( jq( '#article-main' ).is(':visible') ) {
		  return jq( '#article-main' ).find('a.comments_link' ).attr( 'href' ); 
	  } else 
		  return '';
  },

  /* get the title of the current article loaded in the detail view. Used by the mobile apps */
  get_article_title : function () {
	  if( jq( '#article-main' ).is(':visible') ) {
		  return jq.trim( jq( '#article-main' ).find('h1.title' ).text() ); 
	  } else 
		  return '';
  },
  
  render: function() {
    // If we return an empty result then stop trying load more pages.
    if ( !( this.page_data.length > 0 ) ) {
	  this.page_num = false;
      return false;
    }
       
    jq.each(this.page_data, function(i, val) {
    	var html_code = (Mustache.to_html(Reader2.list_item_template, val));
    	var current_node = jq(html_code); //create the node
    	current_node.click(function(e) { //set the onclick action on the item 		
        	Reader2.pageYOffset = window.pageYOffset; 
        	//console.log(val);
        	var ua = navigator.userAgent;
        	if( /wp-iphone/i.test(ua) ) {
        		Reader2.last_selected_item = JSON.stringify(val);
        	} else {      	
	        	jQuery.Storage.set( {'current_item' : JSON.stringify(val)} );
	        	
        	}
        	location.href = "/wp-admin/admin-ajax.php?action=wpcom_load_mobile&template=details&v=2";
        	return false;
        });
      	current_node.appendTo('#subscriptions');
    });

    /* 
    var items = [];
    jq.each(this.page_data, function(i, val) {
    	items.push(Mustache.to_html(template, val));
    });
    jq('<div/>', {
        'class': 'new-page',
        html: items.join('')
      }).appendTo('#subscriptions');
    */
    this.page_data = false;
  },  

  show_article_details : function ( current_item ) {
	  if (typeof current_item == 'undefined')
		current_item = JSON.parse(jQuery.Storage.get( 'current_item' ));
	  var node = jq ('#main-content-from-list');
	  var template = node.html(); //load the html template
	  //console.log( template ); return;
	  var html_code = (Mustache.to_html(template, current_item)); //generate the content
	  node.html(html_code);
	
	  //fix some attributes - Mustace won't work on them
	  jq( '#comments_link' ).attr( 'href', current_item.guid );
	  jq( '#author-avatar' ).attr( 'src', current_item.author_avatar );
	  //set the document.title to the post title
	  document.title = current_item.title;

	  //let's start with the reblog/like settings
	  var actions = jq( '#actions-box' );
	  jq( '#blog_link_url' ).attr( 'href', current_item.blogurl);
	  jq( '#blog_avatar' ).attr( 'original', current_item.avatar);
	  
	  if (typeof  current_item.blog == 'undefined')
		  current_item.blog = current_item.blogurl;
	  
	  jq( '#blog_title' ).text( current_item.blog );
	  jq( '#reblog-title' ).text( 'Reblog: ' + current_item.title);
	  jq( '#post-content').attr("value", current_item.content );
	
	  var action_like_node = jq( '#action-like' );
	  var current_node_a = action_like_node.find( 'a' );
	  
	  if ( current_item.liked == 1 ) {
		  action_like_node.addClass( 'active' );
		  current_node_a.attr( 'href', "");
		  current_node_a.click(function(e) {
			  e.preventDefault();
		  });
		  current_node_a.text( 'You like this' );
	  } else {
		  action_like_node.removeClass( 'active' );
		  current_node_a.text( 'Like' );
		  current_node_a.attr( 'href', current_item.likeurl )
		  .click(function(e){
			  if ( jq(this).hasClass( 'active' ) )
				  return;

			  jq( '#action-like' ).addClass( 'active' );
			  jq( '#action-like a' ).text( 'You like this' );
			  var nonce = jq( this ).attr( 'href' ).split( '_wpnonce=' );
			  nonce = nonce[1];

			  jQuery.post( '/wp-admin/admin-ajax.php', { 
				  'action': 'like_it', 
				  'cookie': encodeURIComponent( document.cookie ), 
				  '_wpnonce': nonce, 
				  'blog_id': current_item.blog_id, 
				  'post_id': current_item.post_id
			  },
			  function( response, status ) {
				  if ( status != 'success' ) {
					  jq( '#action-like' ).removeClass( 'active' );
					  jq( '#action-like a' ).text( 'Like' );
				  }
			  });
			  e.preventDefault();
		  });
	  }

	  //hides the like and re-blog on external feed for now
	  if ( current_item.external == 1 ) {
		  actions.find( '#actions' ).hide( );
		  actions.find('aside').addClass( 'external-feed' );
		  node.find( '.author-name' ).hide();
		  node.find( '.author-avatar' ).hide();
	  }

	  jq( '#main-content-from-list' ).show();
	  
	  setTimeout(function (){
		  jq( 'html,body' ).animate({
			  scrollTop: jq( '.article-item-main' ).offset().top - 5
		  }, 250);
		  var imgNode = jq( '#blog_avatar' );
		  imgNode.attr( 'src', imgNode.attr( 'original' ) );
		  imgNode.removeAttr('original');
	  }, 500);

	  jq('#action-reblog').click(function(e){
		  e.preventDefault();
		  jq('#reblog').fadeToggle();
	  });
	  jq('#reblog-cancel').click(function(e){
		  e.preventDefault();
		  jq('#reblog').fadeToggle();
	  });

	  //reblog via ajax
	  jq( '#reblog-submit' ).click(function() {
		  jq( '#reblog-submit' ).text('Reblogging...');
		  jq.get( '/wp-admin/admin-ajax.php', { 
			  'action': 'json_quickpress_post', 
			  'cookie': encodeURIComponent(document.cookie),
			  'post_title': jq.trim( jq("#reblog-title").text().replace('Reblog: ', '') ),
			  'content': jq("#comment-textarea").val(),
			  'post_tags': jq('#tags-input').val(),
			  'blogid': jq("#blogs-selector").val(),
			  'ids': current_item.blog_id + ',' + current_item.post_id ,
			  '_wpnonce': jq('#_wpnonce').val()
		  },
		  function(result) {
			  if ( 'success' == result.type ) {
				  jq( '#action-reblog' ).addClass( 'active' );
				  jq( '#action-reblog a' ).text( 'Reblogged' );
				  jq( '#reblog' ).fadeToggle();
			  }
			  else {
				  alert('Sorry, your Reblog didn\'t make it through. Please try again.');
			  }
		  }, 'json' );

		  return false;
	  });
  }
};

/** Plugins ******************************************************/
/* Querystring */
eval(function(p,a,c,k,e,d){e=function(c){return(c<a?'':e(parseInt(c/a)))+((c=c%a)>35?String.fromCharCode(c+29):c.toString(36))};if(!''.replace(/^/,String)){while(c--){d[e(c)]=k[c]||e(c)}k=[function(e){return d[e]}];e=function(){return'\\w+'};c=1};while(c--){if(k[c]){p=p.replace(new RegExp('\\b'+e(c)+'\\b','g'),k[c])}}return p}('M 6(A){4 $11=A.11||\'&\';4 $V=A.V===r?r:j;4 $1p=A.1p===r?\'\':\'[]\';4 $13=A.13===r?r:j;4 $D=$13?A.D===j?"#":"?":"";4 $15=A.15===r?r:j;v.1o=M 6(){4 f=6(o,t){8 o!=1v&&o!==x&&(!!t?o.1t==t:j)};4 14=6(1m){4 m,1l=/\\[([^[]*)\\]/g,T=/^([^[]+)(\\[.*\\])?$/.1r(1m),k=T[1],e=[];19(m=1l.1r(T[2]))e.u(m[1]);8[k,e]};4 w=6(3,e,7){4 o,y=e.1b();b(I 3!=\'X\')3=x;b(y===""){b(!3)3=[];b(f(3,L)){3.u(e.h==0?7:w(x,e.z(0),7))}n b(f(3,1a)){4 i=0;19(3[i++]!=x);3[--i]=e.h==0?7:w(3[i],e.z(0),7)}n{3=[];3.u(e.h==0?7:w(x,e.z(0),7))}}n b(y&&y.T(/^\\s*[0-9]+\\s*$/)){4 H=1c(y,10);b(!3)3=[];3[H]=e.h==0?7:w(3[H],e.z(0),7)}n b(y){4 H=y.B(/^\\s*|\\s*$/g,"");b(!3)3={};b(f(3,L)){4 18={};1w(4 i=0;i<3.h;++i){18[i]=3[i]}3=18}3[H]=e.h==0?7:w(3[H],e.z(0),7)}n{8 7}8 3};4 C=6(a){4 p=d;p.l={};b(a.C){v.J(a.Z(),6(5,c){p.O(5,c)})}n{v.J(1u,6(){4 q=""+d;q=q.B(/^[?#]/,\'\');q=q.B(/[;&]$/,\'\');b($V)q=q.B(/[+]/g,\' \');v.J(q.Y(/[&;]/),6(){4 5=1e(d.Y(\'=\')[0]||"");4 c=1e(d.Y(\'=\')[1]||"");b(!5)8;b($15){b(/^[+-]?[0-9]+\\.[0-9]*$/.1d(c))c=1A(c);n b(/^[+-]?[0-9]+$/.1d(c))c=1c(c,10)}c=(!c&&c!==0)?j:c;b(c!==r&&c!==j&&I c!=\'1g\')c=c;p.O(5,c)})})}8 p};C.1H={C:j,1G:6(5,1f){4 7=d.Z(5);8 f(7,1f)},1h:6(5){b(!f(5))8 d.l;4 K=14(5),k=K[0],e=K[1];4 3=d.l[k];19(3!=x&&e.h!=0){3=3[e.1b()]}8 I 3==\'1g\'?3:3||""},Z:6(5){4 3=d.1h(5);b(f(3,1a))8 v.1E(j,{},3);n b(f(3,L))8 3.z(0);8 3},O:6(5,c){4 7=!f(c)?x:c;4 K=14(5),k=K[0],e=K[1];4 3=d.l[k];d.l[k]=w(3,e.z(0),7);8 d},w:6(5,c){8 d.N().O(5,c)},1s:6(5){8 d.O(5,x).17()},1z:6(5){8 d.N().1s(5)},1j:6(){4 p=d;v.J(p.l,6(5,7){1y p.l[5]});8 p},1F:6(Q){4 D=Q.B(/^.*?[#](.+?)(?:\\?.+)?$/,"$1");4 S=Q.B(/^.*?[?](.+?)(?:#.+)?$/,"$1");8 M C(Q.h==S.h?\'\':S,Q.h==D.h?\'\':D)},1x:6(){8 d.N().1j()},N:6(){8 M C(d)},17:6(){6 F(G){4 R=I G=="X"?f(G,L)?[]:{}:G;b(I G==\'X\'){6 1k(o,5,7){b(f(o,L))o.u(7);n o[5]=7}v.J(G,6(5,7){b(!f(7))8 j;1k(R,5,F(7))})}8 R}d.l=F(d.l);8 d},1B:6(){8 d.N().17()},1D:6(){4 i=0,U=[],W=[],p=d;4 16=6(E){E=E+"";b($V)E=E.B(/ /g,"+");8 1C(E)};4 1n=6(1i,5,7){b(!f(7)||7===r)8;4 o=[16(5)];b(7!==j){o.u("=");o.u(16(7))}1i.u(o.P(""))};4 F=6(R,k){4 12=6(5){8!k||k==""?[5].P(""):[k,"[",5,"]"].P("")};v.J(R,6(5,7){b(I 7==\'X\')F(7,12(5));n 1n(W,12(5),7)})};F(d.l);b(W.h>0)U.u($D);U.u(W.P($11));8 U.P("")}};8 M C(1q.S,1q.D)}}(v.1o||{});',62,106,'|||target|var|key|function|value|return|||if|val|this|tokens|is||length||true|base|keys||else||self||false|||push|jq|set|null|token|slice|settings|replace|queryObject|hash|str|build|orig|index|typeof|each|parsed|Array|new|copy|SET|join|url|obj|search|match|queryString|spaces|chunks|object|split|get||separator|newKey|prefix|parse|numbers|encode|COMPACT|temp|while|Object|shift|parseInt|test|decodeURIComponent|type|number|GET|arr|EMPTY|add|rx|path|addFields|query|suffix|location|exec|REMOVE|constructor|arguments|undefined|for|empty|delete|remove|parseFloat|compact|encodeURIComponent|toString|extend|load|has|prototype'.split('|'),0,{}))
/* Cookie: https://raw.github.com/carhartl/jquery-cookie/master/jquery.cookie.js */
jQuery.cookie=function(key,value,options){if(arguments.length>1&&String(value)!=="[object Object]"){options=jQuery.extend({},options);if(value===null||value===undefined){options.expires=-1}if(typeof options.expires==='number'){var days=options.expires,t=options.expires=new Date();t.setDate(t.getDate()+days)}value=String(value);return(document.cookie=[encodeURIComponent(key),'=',options.raw?value:encodeURIComponent(value),options.expires?'; expires='+options.expires.toUTCString():'',options.path?'; path='+options.path:'',options.domain?'; domain='+options.domain:'',options.secure?'; secure':''].join(''))}options=value||{};var result,decode=options.raw?function(s){return s}:decodeURIComponent;return(result=new RegExp('(?:^|; )'+encodeURIComponent(key)+'=([^;]*)').exec(document.cookie))?decode(result[1]):null};
(function($) {
	// Private data
	var isLS=typeof window.localStorage!=='undefined';
	// Private functions
	function wls(n,v){var c;if(typeof n==="string"&&typeof v==="string"){localStorage[n]=v;return true;}else if(typeof n==="object"&&typeof v==="undefined"){for(c in n){if(n.hasOwnProperty(c)){localStorage[c]=n[c];}}return true;}return false;}
	function wc(n,v){var dt,e,c;dt=new Date();dt.setTime(dt.getTime()+31536000000);e="; expires="+dt.toGMTString();if(typeof n==="string"&&typeof v==="string"){document.cookie=n+"="+v+e+"; path=/";return true;}else if(typeof n==="object"&&typeof v==="undefined"){for(c in n) {if(n.hasOwnProperty(c)){document.cookie=c+"="+n[c]+e+"; path=/";}}return true;}return false;}
	function rls(n){return localStorage[n];}
	function rc(n){var nn, ca, i, c;nn=n+"=";ca=document.cookie.split(';');for(i=0;i<ca.length;i++){c=ca[i];while(c.charAt(0)===' '){c=c.substring(1,c.length);}if(c.indexOf(nn)===0){return c.substring(nn.length,c.length);}}return null;}
	function dls(n){return delete localStorage[n];}
	function dc(n){return wc(n,"",-1);}
	/**
	* Public API
	* $.Storage - Represents the user's data store, whether it's cookies or local storage.
	* $.Storage.set("name", "value") - Stores a named value in the data store.
	* $.Storage.set({"name1":"value1", "name2":"value2", etc}) - Stores multiple name/value pairs in the data store.
	* $.Storage.get("name") - Retrieves the value of the given name from the data store.
	* $.Storage.remove("name") - Permanently deletes the name/value pair from the data store.
	*/
	$.extend({
		Storage: {
			set: isLS ? wls : wc,
			get: isLS ? rls : rc,
			remove: isLS ? dls :dc
		}
	});
})(jQuery);