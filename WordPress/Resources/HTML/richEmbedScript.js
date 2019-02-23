
// This script is used by WPRichTextEmbeds to get the internal scroll width and
// height of a loaded page. The size reported by a WKWebView.scrollView.contentSize
// is often inaccurate, ergo this script.
//
// Video tags get special treatment. A tag without width/height attributes
// will update its geometry--and thus the document's geometry--only after it
// finishes loading its metadata. Something that happens after the page is loaded.
//
// Geometry is reported as a formatted string to a WKScriptMessageHandler named
// "observer".
//

// Get the document's scroll size and send it to the observer.
//
function reportDocumentSize() {
    var w = document.documentElement.scrollWidth;
    var h = document.documentElement.scrollHeight;
    reportSize( w, h );
}

function reportSize( w, h ) {
    var msg = "" + w + "," + h;
    window.webkit.messageHandlers.observer.postMessage(msg);
}

function metadataLoadedHandler( event ) {
    var video = event.target;
    var w = video.videoWidth;
    var h = video.videoHeight;
    var docElement = document.documentElement;
    if ( w > docElement.scrollWidth || h > docElement.scrollHeight ) {
        reportSize( w, h );
    } else {
        reportDocumentSize();
    }
}

function listenForMetaData( videoTag ) {
    videoTag.addEventListener( 'loadedmetadata', metadataLoadedHandler );
}


// If there are video tags listen for meta data to be loaded.
// If no tags go ahead and report document size.
//
function onLoadHandler( event ) {
    var videoTags = document.getElementsByTagName( "video" );
    if ( videoTags.length > 0 ) {
        listenForMetaData( videoTags[0] );
        return;
    }
    reportDocumentSize();
}

window.addEventListener( 'load', onLoadHandler);



// This script is used to override a page's specified viewport to one
// better suited to our usecase.
//
var timerID = setInterval( function() {
                          if ( document.readyState != 'complete' ) {
                            return;
                          }
                          clearInterval( timerID );
                          var viewport = document.querySelector( 'meta[name=viewport]' );
                          if ( viewport ) {
                            viewport.setAttribute('content', 'width=available-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no');
                          }
}, 100 );
