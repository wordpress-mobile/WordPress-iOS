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

zss_editor.defaultCallbackSeparator = ',';

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

	document.addEventListener("selectionchange", function(e) {
		zss_editor.currentEditingLink = null;
							  
		// DRM: only do something here if the editor has focus.  The reason is that when the
		// selection changes due to the editor loosing focus, the focusout event will not be
		// sent if we try to load a callback here.
		//
		if (editor.is(":focus")) {
			zss_editor.sendEnabledStyles(e);
			var clicked = $(e.target);
			if (!clicked.hasClass('zs_active')) {
				$('img').removeClass('zs_active');
			}
		}
	}, false);

	editor.bind('tap', function(e) {
				
		setTimeout(function() {
			var targetNode = e.target;
			var arguments = ['url=' + encodeURIComponent(targetNode.href),
							 'title=' + encodeURIComponent(targetNode.innerHTML)];
				   
			if (targetNode.nodeName.toLowerCase() == 'a') {
				zss_editor.callback('callback-link-tap',
									arguments.join(zss_editor.defaultCallbackSeparator));
			}
		}, 400);
	});
	
	editor.bind('focus', function(e) {
		zss_editor.callback("callback-focus-in");
	});
	
	editor.bind('blur', function(e) {
		zss_editor.callback("callback-focus-out");
	});
	
	editor.bind('keyup', function(e) {
		zss_editor.sendEnabledStyles(e);
		zss_editor.callback("callback-user-triggered-change");
	});

}//end

zss_editor.log = function(msg) {
	zss_editor.callback(callback-log, msg);
}

zss_editor.domLoadedCallback = function() {
	
	zss_editor.callback("callback-dom-loaded");
}

zss_editor.callback = function(callbackScheme, callbackPath) {
	
	var url =  callbackScheme + ":";
 
	if (callbackPath) {
		url = url + callbackPath;
	}
	
	if (zss_editor.isUsingiOS) {
		window.location = url;
	} else {
		console.log(url);
	}
}

zss_editor.stylesCallback = function(stylesArray) {

	var stylesString = '';
	
	if (stylesArray.length > 0) {
		stylesString = stylesArray.join(zss_editor.defaultCallbackSeparator);
	}

	zss_editor.callback("callback-selection-style", stylesString);
}

zss_editor.backuprange = function(){
	var selection = window.getSelection();
    var range = selection.getRangeAt(0);
    zss_editor.currentSelection = {"startContainer": range.startContainer, "startOffset":range.startOffset,"endContainer":range.endContainer, "endOffset":range.endOffset};
}

zss_editor.restoreRange = function(){
	var selection = window.getSelection();
    selection.removeAllRanges();
    var range = document.createRange();
    range.setStart(zss_editor.currentSelection.startContainer, zss_editor.currentSelection.startOffset);
    range.setEnd(zss_editor.currentSelection.endContainer, zss_editor.currentSelection.endOffset);
    selection.addRange(range);
}

zss_editor.getSelectedText = function() {
	var selection = window.getSelection();
	
	return selection.toString();
}

zss_editor.setBold = function() {
	document.execCommand('bold', false, null);
	zss_editor.sendEnabledStyles();
}

zss_editor.setItalic = function() {
	document.execCommand('italic', false, null);
	zss_editor.sendEnabledStyles();
}

zss_editor.setSubscript = function() {
	document.execCommand('subscript', false, null);
	zss_editor.sendEnabledStyles();
}

zss_editor.setSuperscript = function() {
	document.execCommand('superscript', false, null);
	zss_editor.sendEnabledStyles();
}

zss_editor.setStrikeThrough = function() {
	var commandName = 'strikeThrough';
	var isDisablingStrikeThrough = zss_editor.isCommandEnabled(commandName);
	
	document.execCommand(commandName, false, null);
	
	// DRM: WebKit has a problem disabling strikeThrough when the tag <del> is used instead of
	// <strike>.  The code below serves as a way to fix this issue.
	//
	var mustHandleWebKitIssue = (isDisablingStrikeThrough
								 && zss_editor.isCommandEnabled(commandName));
	
	if (mustHandleWebKitIssue) {
		var troublesomeNodeNames = ['del'];
		
		var selection = window.getSelection();
		var range = selection.getRangeAt(0).cloneRange();
		
		var container = range.commonAncestorContainer;
		var nodeFound = false;
		var textNode = null;
		
		while (container && !nodeFound) {
			nodeFound = (container
						 && container.nodeType == document.ELEMENT_NODE
						 && troublesomeNodeNames.indexOf(container.nodeName.toLowerCase()) > -1);
			
			if (!nodeFound) {
				container = container.parentElement;
			}
		}
		
		if (container) {
			var newObject = $(container).replaceWith(container.innerHTML);
			
			var finalSelection = window.getSelection();
			var finalRange = selection.getRangeAt(0).cloneRange();
			
			finalRange.setEnd(finalRange.startContainer, finalRange.startOffset + 1);
			
			selection.removeAllRanges();
			selection.addRange(finalRange);
		}
	}
	
	zss_editor.sendEnabledStyles();
}

zss_editor.setUnderline = function() {
	document.execCommand('underline', false, null);
	zss_editor.sendEnabledStyles();
}

zss_editor.setBlockquote = function() {
	var formatTag = "blockquote";
	var formatBlock = document.queryCommandValue('formatBlock');
	 
	if (formatBlock.length > 0 && formatBlock.toLowerCase() == formatTag) {
		document.execCommand('formatBlock', false, '<div>');
	} else {
		document.execCommand('formatBlock', false, '<' + formatTag + '>');
	}

	 zss_editor.sendEnabledStyles();

	/* DRM: the following code has been disabled for the time being, but it's a good starting point
	 for being able to apply blockquote to your selection only.
	 
	var formatBlock = document.queryCommandValue('formatBlock');
	
	if (formatBlock.length > 0 && formatBlock.toLowerCase() == "blockquote") {

		var selection = document.getSelection();
		alert(selection);
		var range = selection.getRangeAt(0).cloneRange();
		alert(range);
		var container = range.commonAncestorContainer;
		
		alert(container.nodeName);
		
		while (container && container.elementName != "blockquote")
		{
			container = container.parentElement();
		}
		
		if (container) {
			container.contents().unwrap();
		}
	} else {
		var selection = document.getSelection();
		
		if (selection) {
			if (selection.rangeCount) {
				
				var elementName = "blockquote";
				var el = document.createElement(elementName);
				
				var range = selection.getRangeAt(0).cloneRange();
				range.surroundContents(el);
				
				range.selectNodeContents(el)
				
				selection.removeAllRanges();
				selection.addRange(range);
			}
		}
	}
	
	zss_editor.sendEnabledStyles();
	 */
}

zss_editor.removeFormating = function() {
	document.execCommand('removeFormat', false, null);
	zss_editor.sendEnabledStyles();
}

zss_editor.setHorizontalRule = function() {
	document.execCommand('insertHorizontalRule', false, null);
	zss_editor.sendEnabledStyles();
}

zss_editor.setHeading = function(heading) {
	var formatTag = heading;
	var formatBlock = document.queryCommandValue('formatBlock');
	
	if (formatBlock.length > 0 && formatBlock.toLowerCase() == formatTag) {
		document.execCommand('formatBlock', false, '<div>');
	} else {
		document.execCommand('formatBlock', false, '<' + formatTag + '>');
	}
	
	zss_editor.sendEnabledStyles();
}

zss_editor.setParagraph = function() {
	var formatTag = "p";
	var formatBlock = document.queryCommandValue('formatBlock');
	
	if (formatBlock.length > 0 && formatBlock.toLowerCase() == formatTag) {
		document.execCommand('formatBlock', false, '<div>');
	} else {
		document.execCommand('formatBlock', false, '<' + formatTag + '>');
	}
	
	zss_editor.sendEnabledStyles();
}

zss_editor.undo = function() {
	document.execCommand('undo', false, null);
	zss_editor.sendEnabledStyles();
}

zss_editor.redo = function() {
	document.execCommand('redo', false, null);
	zss_editor.sendEnabledStyles();
}

zss_editor.setOrderedList = function() {
	document.execCommand('insertOrderedList', false, null);
	zss_editor.sendEnabledStyles();
}

zss_editor.setUnorderedList = function() {
	document.execCommand('insertUnorderedList', false, null);
	zss_editor.sendEnabledStyles();
}

zss_editor.setJustifyCenter = function() {
	document.execCommand('justifyCenter', false, null);
	zss_editor.sendEnabledStyles();
}

zss_editor.setJustifyFull = function() {
	document.execCommand('justifyFull', false, null);
	zss_editor.sendEnabledStyles();
}

zss_editor.setJustifyLeft = function() {
	document.execCommand('justifyLeft', false, null);
	zss_editor.sendEnabledStyles();
}

zss_editor.setJustifyRight = function() {
	document.execCommand('justifyRight', false, null);
	zss_editor.sendEnabledStyles();
}

zss_editor.setIndent = function() {
	document.execCommand('indent', false, null);
	zss_editor.sendEnabledStyles();
}

zss_editor.setOutdent = function() {
	document.execCommand('outdent', false, null);
	zss_editor.sendEnabledStyles();
}

zss_editor.setTextColor = function(color) {
    zss_editor.restoreRange();
	document.execCommand("styleWithCSS", null, true);
	document.execCommand('foreColor', false, color);
	document.execCommand("styleWithCSS", null, false);
	zss_editor.sendEnabledStyles();
    // document.execCommand("removeFormat", false, "foreColor"); // Removes just foreColor
}

zss_editor.setBackgroundColor = function(color) {
	zss_editor.restoreRange();
	document.execCommand("styleWithCSS", null, true);
	document.execCommand('hiliteColor', false, color);
	document.execCommand("styleWithCSS", null, false);
	zss_editor.sendEnabledStyles();
}

// Needs addClass method

zss_editor.insertLink = function(url, title) {

    zss_editor.restoreRange();
	
    var sel = document.getSelection();
	if (sel.rangeCount) {

		var el = document.createElement("a");
		el.setAttribute("href", url);
		
		var range = sel.getRangeAt(0).cloneRange();
		range.surroundContents(el);
		el.innerHTML = title;
		sel.removeAllRanges();
		sel.addRange(range);
	}

	zss_editor.sendEnabledStyles();
}

zss_editor.updateLink = function(url, title) {
	
    zss_editor.restoreRange();
	
	var currentLinkNode = zss_editor.closerParentNode('a');
	
    if (currentLinkNode) {
		currentLinkNode.setAttribute("href", url);
		currentLinkNode.innerHTML = title;
    }
    zss_editor.sendEnabledStyles();
}

zss_editor.unlink = function() {
	
	var currentLinkNode = zss_editor.closerParentNode('a');
	
	if (currentLinkNode) {
		zss_editor.unwrapNode(currentLinkNode);
	}
	
	zss_editor.sendEnabledStyles();
}

zss_editor.updateImage = function(url, alt) {

    zss_editor.restoreRange();

    if (zss_editor.currentEditingImage) {
        var c = zss_editor.currentEditingImage;
        c.attr('src', url);
        c.attr('alt', alt);
    }
    zss_editor.sendEnabledStyles();

}//end

zss_editor.unwrapNode = function(node) {
	var newObject = $(node).replaceWith(node.innerHTML);
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
	zss_editor.restoreRange();
	var html = '<img src="'+url+'" alt="'+alt+'" />';
	zss_editor.insertHTML(html);
	zss_editor.sendEnabledStyles();
}

zss_editor.setHTML = function(html) {
	var editor = $('#zss_editor_content');
	editor.html(html);
}

zss_editor.insertHTML = function(html) {
	document.execCommand('insertHTML', false, html);
	zss_editor.sendEnabledStyles();
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

zss_editor.closerParentNode = function(nodeName) {
	
	nodeName = nodeName.toLowerCase();
	
	var parentNode = null;
	var selection = window.getSelection();
	var range = selection.getRangeAt(0).cloneRange();
	
	var currentNode = range.commonAncestorContainer;
	
	while (currentNode) {
		
		if (currentNode.nodeName == document.body.nodeName) {
			break;
		}
		
		if (currentNode.nodeName.toLowerCase() == nodeName
			&& currentNode.nodeType == document.ELEMENT_NODE) {
			parentNode = currentNode;
			
			break;
		}
		
		currentNode = currentNode.parentElement;
	}
	
	return parentNode;
}

zss_editor.parentTags = function() {
	
	var parentTags = [];
	var selection = window.getSelection();
	var range = selection.getRangeAt(0);
	
	var currentNode = range.commonAncestorContainer;
	while (currentNode) {
		
		if (currentNode.nodeName == document.body.nodeName) {
			break;
		}
		
		if (currentNode.nodeType == document.ELEMENT_NODE) {
			parentTags.push(currentNode);
		}
		
		currentNode = currentNode.parentElement;
	}
	
	return parentTags;
}

zss_editor.sendEnabledStyles = function(e) {
	
	var items = [];
	
	// Find all relevant parent tags
	var parentTags = zss_editor.parentTags();
	
	for (var i = 0; i < parentTags.length; i++) {
		var currentNode = parentTags[i];
		
		if (currentNode.nodeName.toLowerCase() == 'a') {
			zss_editor.currentEditingLink = currentNode;
			
			var title = encodeURIComponent(currentNode.text);
			var href = encodeURIComponent(currentNode.href);
			
			items.push('link-title:' + title);
			items.push('link:' + href);
		}
	}
	
	if (zss_editor.isCommandEnabled('bold')) {
		items.push('bold');
	}
	if (zss_editor.isCommandEnabled('createLink')) {
		items.push('createLink');
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
		var isUnderlined = false;
		
		// DRM: 'underline' gets highlighted if it's inside of a link... so we need a special test
		// in that case.
		if (!zss_editor.currentEditingLink) {
			items.push('underline');
		}
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
		
		// The target element
		var t = $(e.target);
		var nodeName = e.target.nodeName.toLowerCase();
        console.log(nodeName);
		
		// Background Color
		try
		{
			var bgColor = t.css('backgroundColor');
			if (bgColor && bgColor.length != 0 && bgColor != 'rgba(0, 0, 0, 0)' && bgColor != 'rgb(0, 0, 0)' && bgColor != 'transparent') {
				items.push('backgroundColor');
			}
		}
		catch(e)
		{
			// DRM: I had to add these stupid try-catch blocks to solve an issue with t.css throwing
			// exceptions for no reason.
		}
		
		// Text Color
		try
		{
			var textColor = t.css('color');
			if (textColor && textColor.length != 0 && textColor != 'rgba(0, 0, 0, 0)' && textColor != 'rgb(0, 0, 0)' && textColor != 'transparent') {
				items.push('textColor');
			}
		}
		catch(e)
		{
			// DRM: I had to add these stupid try-catch blocks to solve an issue with t.css throwing
			// exceptions for no reason.
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
	
	zss_editor.stylesCallback(items);
}

zss_editor.isFocused = function() {

	return $('#zss_editor_content').is(":focus");
}

zss_editor.focusEditor = function() {

	if (!zss_editor.isFocused()) {
		$('#zss_editor_content').focus();
	}
}

zss_editor.blurEditor = function() {
	if (zss_editor.isFocused()) {
		$('#zss_editor_content').blur();
	}
}

zss_editor.enableEditing = function () {
	document.body.contentEditable = true;
}

zss_editor.disableEditing = function () {
    zss_editor.blurEditor();
	document.body.contentEditable = false;
}
