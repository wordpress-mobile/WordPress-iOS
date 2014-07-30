/*!
 *
 * ZSSRichTextEditor v1.0
 * http://www.zedsaid.com
 *
 * Copyright 2013 Zed Said Studio
 *
 */

// The editor object
var zss_editor = {};

// If we are using iOS or desktop
zss_editor.isUsingiOS = true;

// The current selection
zss_editor.currentSelection;

// The current editing image
zss_editor.currentEditingImage;

// The current editing link
zss_editor.currentEditingLink;

// The objects that are enabled
zss_editor.enabledItems = {};

/**
 * The initializer function that must be called onLoad
 */
zss_editor.init = function() {
	
	// Main editor div
	var editor = $('#zss_editor_content');
	editor.trigger('touchstart');
	
	// Bind an event so we always know what styles are applied
	editor.bind('touchend', function(e) {
		zss_editor.enabledEditingItems(e);
		var clicked = $(e.target);
		if (!clicked.hasClass('zs_active')) {
			$('img').removeClass('zs_active');
		}
	});
}//end

zss_editor.backuprange = function(){
	var selection = window.getSelection();
    var range = selection.getRangeAt(0);
    zss_editor.currentSelection = {"startContainer": range.startContainer, "startOffset":range.startOffset,"endContainer":range.endContainer, "endOffset":range.endOffset};
}

zss_editor.restorerange = function(){
	var selection = window.getSelection();
    selection.removeAllRanges();
    var range = document.createRange();
    range.setStart(zss_editor.currentSelection.startContainer, zss_editor.currentSelection.startOffset);
    range.setEnd(zss_editor.currentSelection.endContainer, zss_editor.currentSelection.endOffset);
    selection.addRange(range);
}

zss_editor.setBold = function() {
	document.execCommand('bold', false, null);
	zss_editor.enabledEditingItems();
}

zss_editor.setItalic = function() {
	document.execCommand('italic', false, null);
	zss_editor.enabledEditingItems();
}

zss_editor.setSubscript = function() {
	document.execCommand('subscript', false, null);
	zss_editor.enabledEditingItems();
}

zss_editor.setSuperscript = function() {
	document.execCommand('superscript', false, null);
	zss_editor.enabledEditingItems();
}

zss_editor.setStrikeThrough = function() {
	document.execCommand('strikeThrough', false, null);
	zss_editor.enabledEditingItems();
}

zss_editor.setUnderline = function() {
	document.execCommand('underline', false, null);
	zss_editor.enabledEditingItems();
}

zss_editor.setBlockquote = function() {
	document.execCommand('formatBlock', false, '<blockquote>');
	zss_editor.enabledEditingItems();
}

zss_editor.removeFormating = function() {
	document.execCommand('removeFormat', false, null);
	zss_editor.enabledEditingItems();
}

zss_editor.setHorizontalRule = function() {
	document.execCommand('insertHorizontalRule', false, null);
	zss_editor.enabledEditingItems();
}

zss_editor.setHeading = function(heading) {
	document.execCommand('formatBlock', false, '<'+heading+'>');
	zss_editor.enabledEditingItems();
}

zss_editor.setParagraph = function() {
	document.execCommand('formatBlock', false, '<p>');
	zss_editor.enabledEditingItems();
}

// Need way to remove formatBlock
console.log('WARNING: We need a way to remove formatBlock items');

zss_editor.undo = function() {
	document.execCommand('undo', false, null);
	zss_editor.enabledEditingItems();
}

zss_editor.redo = function() {
	document.execCommand('redo', false, null);
	zss_editor.enabledEditingItems();
}

zss_editor.setOrderedList = function() {
	document.execCommand('insertOrderedList', false, null);
	zss_editor.enabledEditingItems();
}

zss_editor.setUnorderedList = function() {
	document.execCommand('insertUnorderedList', false, null);
	zss_editor.enabledEditingItems();
}

zss_editor.setJustifyCenter = function() {
	document.execCommand('justifyCenter', false, null);
	zss_editor.enabledEditingItems();
}

zss_editor.setJustifyFull = function() {
	document.execCommand('justifyFull', false, null);
	zss_editor.enabledEditingItems();
}

zss_editor.setJustifyLeft = function() {
	document.execCommand('justifyLeft', false, null);
	zss_editor.enabledEditingItems();
}

zss_editor.setJustifyRight = function() {
	document.execCommand('justifyRight', false, null);
	zss_editor.enabledEditingItems();
}

zss_editor.setIndent = function() {
	document.execCommand('indent', false, null);
	zss_editor.enabledEditingItems();
}

zss_editor.setOutdent = function() {
	document.execCommand('outdent', false, null);
	zss_editor.enabledEditingItems();
}

zss_editor.setTextColor = function(color) {
    zss_editor.restorerange();
	document.execCommand("styleWithCSS", null, true);
	document.execCommand('foreColor', false, color);
	document.execCommand("styleWithCSS", null, false);
	zss_editor.enabledEditingItems();
    // document.execCommand("removeFormat", false, "foreColor"); // Removes just foreColor
}

zss_editor.setBackgroundColor = function(color) {
	zss_editor.restorerange();
	document.execCommand("styleWithCSS", null, true);
	document.execCommand('hiliteColor', false, color);
	document.execCommand("styleWithCSS", null, false);
	zss_editor.enabledEditingItems();
}

// Needs addClass method

zss_editor.insertLink = function(url, title) {
	
    zss_editor.restorerange();
    var sel = document.getSelection();
	if (sel.toString().length != 0) {
        if (sel.rangeCount) {
			
			var el = document.createElement("a");
    		el.setAttribute("href", url);
            el.setAttribute("title", title);
			
            var range = sel.getRangeAt(0).cloneRange();
            range.surroundContents(el);
            sel.removeAllRanges();
            sel.addRange(range);
        }
	}
	zss_editor.enabledEditingItems();
}

zss_editor.updateLink = function(url, title) {
	
    zss_editor.restorerange();
	
    if (zss_editor.currentEditingLink) {
        var c = zss_editor.currentEditingLink;
        c.attr('href', url);
        c.attr('title', title);
    }
    zss_editor.enabledEditingItems();
    
}//end

zss_editor.updateImage = function(url, alt) {
	
    zss_editor.restorerange();
	
    if (zss_editor.currentEditingImage) {
        var c = zss_editor.currentEditingImage;
        c.attr('src', url);
        c.attr('alt', alt);
    }
    zss_editor.enabledEditingItems();
	
}//end

zss_editor.unlink = function() {
    
	if (zss_editor.currentEditingLink) {
        var c = zss_editor.currentEditingLink;
        c.contents().unwrap();
    }
    zss_editor.enabledEditingItems();
}

zss_editor.quickLink = function() {
	
	var sel = document.getSelection();
	var link_url = "";
	var test = new String(sel);
	var mailregexp = new RegExp("^(.+)(\@)(.+)$", "gi");
	if (test.search(mailregexp) == -1) {
		checkhttplink = new RegExp("^http\:\/\/", "gi");
		if (test.search(checkhttplink) == -1) {
			checkanchorlink = new RegExp("^\#", "gi");
			if (test.search(checkanchorlink) == -1) {
				link_url = "http://" + sel;
			} else {
				link_url = sel;
			}
		} else {
			link_url = sel;
		}
	} else {
		checkmaillink = new RegExp("^mailto\:", "gi");
		if (test.search(checkmaillink) == -1) {
			link_url = "mailto:" + sel;
		} else {
			link_url = sel;
		}
	}

	var html_code = '<a href="' + link_url + '">' + sel + '</a>';
	zss_editor.insertHTML(html_code);
	
}

zss_editor.prepareInsert = function() {
	zss_editor.backuprange();	
}

zss_editor.insertImage = function(url, alt) {
	zss_editor.restorerange();
	var html = '<img src="'+url+'" alt="'+alt+'" />';
	zss_editor.insertHTML(html);
	zss_editor.enabledEditingItems();
}

zss_editor.setHTML = function(html) {
	var editor = $('#zss_editor_content');
	editor.html(html);
}

zss_editor.insertHTML = function(html) {
	document.execCommand('insertHTML', false, html);
	zss_editor.enabledEditingItems();
}

zss_editor.getHTML = function() {
	
	// Images
	var img = $('img');
	if (img.length != 0) {
		$('img').removeClass('zs_active');
		$('img').each(function(index, e) {
			var image = $(this);
			var zs_class = image.attr('class');
			if (typeof(zs_class) != "undefined") {
				if (zs_class == '') {
					image.removeAttr('class');
				}
			}
		});
	}
    
    // Blockquote
    var bq = $('blockquote');
    if (bq.length != 0) {
        bq.each(function() {
            var b = $(this);
			if (b.css('border').indexOf('none') != -1) {
				b.css({'border': ''});
			}
			if (b.css('padding').indexOf('0px') != -1) {
				b.css({'padding': ''});
			}
        });
    }

	// Get the contents
	var h = document.getElementById("zss_editor_content").innerHTML;    
	return h;
}

zss_editor.isCommandEnabled = function(commandName) {
	return document.queryCommandState(commandName);
}

zss_editor.enabledEditingItems = function(e) {
	
	var items = [];
	if (zss_editor.isCommandEnabled('bold')) {
		items.push('bold');
	} 
	if (zss_editor.isCommandEnabled('italic')) {
		items.push('italic');
	}
	if (zss_editor.isCommandEnabled('subscript')) {
		items.push('subscript');
	}
	if (zss_editor.isCommandEnabled('superscript')) {
		items.push('superscript');
	}
	if (zss_editor.isCommandEnabled('strikeThrough')) {
		items.push('strikeThrough');
	}
	if (zss_editor.isCommandEnabled('underline')) {
		items.push('underline');
	}
	if (zss_editor.isCommandEnabled('insertOrderedList')) {
		items.push('orderedList');
	}
	if (zss_editor.isCommandEnabled('insertUnorderedList')) {
		items.push('unorderedList');
	}
	if (zss_editor.isCommandEnabled('justifyCenter')) {
		items.push('justifyCenter');
	}
	if (zss_editor.isCommandEnabled('justifyFull')) {
		items.push('justifyFull');
	}
	if (zss_editor.isCommandEnabled('justifyLeft')) {
		items.push('justifyLeft');
	}
	if (zss_editor.isCommandEnabled('justifyRight')) {
		items.push('justifyRight');
	}
    if (zss_editor.isCommandEnabled('insertHorizontalRule')) {
		items.push('horizontalRule');
	}
	var formatBlock = document.queryCommandValue('formatBlock');
	if (formatBlock.length > 0) {
		items.push(formatBlock);
	}
    // Images
	$('img').bind('touchstart', function(e) {
        $('img').removeClass('zs_active');
        $(this).addClass('zs_active');
    });
	
	// Use jQuery to figure out those that are not supported
	if (typeof(e) != "undefined") {
		//alert($(e.target).css('textAlign'));
		
		// The target element
		var t = $(e.target);
		var nodeName = e.target.nodeName.toLowerCase();
        console.log(nodeName);
		
		// Background Color
		var bgColor = t.css('backgroundColor');
		if (bgColor.length != 0 && bgColor != 'rgba(0, 0, 0, 0)' && bgColor != 'rgb(0, 0, 0)' && bgColor != 'transparent') {
			items.push('backgroundColor');
		}
		// Text Color
		var textColor = t.css('color');
		if (textColor.length != 0 && textColor != 'rgba(0, 0, 0, 0)' && textColor != 'rgb(0, 0, 0)' && textColor != 'transparent') {
			items.push('textColor');
		}
		// Link
		if (nodeName == 'a') {
            zss_editor.currentEditingLink = t;
			var title = t.attr('title');
            items.push('link:'+t.attr('href'));
            if (t.attr('title') !== undefined) {
                items.push('link-title:'+t.attr('title'));
            }
            
		} else {
			zss_editor.currentEditingLink = null;
		}
        // Blockquote
        if (nodeName == 'blockquote') {
			items.push('indent');
		}
        // Image
        if (nodeName == 'img') {
            zss_editor.currentEditingImage = t;
            items.push('image:'+t.attr('src'));
            if (t.attr('alt') !== undefined) {
                items.push('image-alt:'+t.attr('alt'));
            }
            
        } else {
            zss_editor.currentEditingImage = null;
        }
			
	}
	
	if (items.length > 0) {
		if (zss_editor.isUsingiOS) {
			window.location = "callback://"+items.join(',');
		} else {
			console.log("callback://"+items.join(','));
		}
	} else {
		if (zss_editor.isUsingiOS) {
			window.location = "callback://";
		} else {
			console.log("callback://");
		}
	}
	
}

zss_editor.focusEditor = function() {
    // the following was taken from http://stackoverflow.com/questions/1125292/how-to-move-cursor-to-end-of-contenteditable-entity/3866442#3866442
    // and ensures we move the cursor to the end of the editor
    var range = document.createRange();
    range.selectNodeContents($('#zss_editor_content').get(0));
    range.collapse(false);
    var selection = window.getSelection();
    selection.removeAllRanges();
    selection.addRange(range);
    $('#zss_editor_content').focus();
}

zss_editor.blurEditor = function() {
    $('#zss_editor_content').blur();
}
