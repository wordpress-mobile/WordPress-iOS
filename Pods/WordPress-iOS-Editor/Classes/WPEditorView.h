//
//  WPEditorView.h
//  Pods
//
//  Created by Diego E. Rey Mendez on 8/27/14.
//
//

#import <UIKit/UIKit.h>

@class WPEditorView;

@protocol WPEditorViewDelegate <UIWebViewDelegate>
@optional

/**
 *	@brief		Received when the editor text is changed.
 *
 *	@param		editorView		The editor view.
 */
- (void)editorTextDidChange:(WPEditorView*)editorView;

/**
 *	@brief		Received when the underlying web content's DOM is ready.
 *	@details	The content never completely loads while offline under some circumstances.
 *				This event offers an alternative to start working on the page's contents.
 *
 *	@param		editorView		The editor view.
 */
- (void)editorViewDidFinishLoadingDOM:(WPEditorView*)editorView;

/**
 *	@brief		Received when all of the web content is ready.
 *	@details	The content never completely loads while offline under some circumstances.
 *				This event offers an alternative to start working on the page's contents.
 *
 *	@param		editorView		The editor view.
 */
- (void)editorViewDidFinishLoading:(WPEditorView*)editorView;

/**
 *	@brief		Received when the editor focus changes.
 *
 *	@param		editorView		The editor view.
 *	@param		gained			YES means the focus was gained by the editor.  NO means it was lost.
 */
- (void)editorView:(WPEditorView*)editorView
	  focusChanged:(BOOL)gained;

/**
 *	@brief		Received when the selection is changed.
 *	@details	Useful to know what styles surround the current selection.
 *
 *	@param		editorView		The editor view.
 *	@param		styles			The styles that surround the current selection.
 */
-        (void)editorView:(WPEditorView*)editorView
stylesForCurrentSelection:(NSArray*)styles;

/**
 *	@brief		Received when the underlying HTML needs us to log a debug message.
 *
 *	@param		editorView		The editor view.
 *	@param		message			The message to log.
 *	@param		isError			YES means the message is an error.  NO means it's just a log
 *								message.
 */
- (void)editorView:(WPEditorView*)editorView
			   log:(NSString*)message
		   isError:(BOOL)isError;
@end

@interface WPEditorView : UIView

@property (nonatomic, weak, readwrite) id<WPEditorViewDelegate> delegate;
@property (nonatomic, assign, readwrite, getter = isEditing) BOOL editing;

// DRM: TODO: after the full migration is complete... make this property private only.
@property (nonatomic, strong, readonly) UIWebView* webView;

#pragma mark - Interaction

- (void)setHtml:(NSString *)html;
- (void)insertHTML:(NSString *)html;
- (NSString *)getHTML;

#pragma mark - Editor focus

- (void)focusTextEditor;
- (void)blurTextEditor;

#pragma mark - Editor mode

- (BOOL)isInVisualMode;
- (void)showHTMLSource;
- (void)showVisualEditor;

#pragma mark - Editing lock

- (void)disableEditing;
- (void)enableEditing;

#pragma mark - Customization

- (void)setInputAccessoryView:(UIView*)inputAccessoryView;


#pragma mark - Styles

- (void)removeFormat;
- (void)alignLeft;
- (void)alignCenter;
- (void)alignRight;
- (void)alignFull;
- (void)setBold;
- (void)setBlockQuote;
- (void)setItalic;
- (void)setSubscript;
- (void)setUnderline;
- (void)setSuperscript;
- (void)setStrikethrough;
- (void)setUnorderedList;
- (void)setOrderedList;
- (void)setHR;
- (void)setIndent;
- (void)setOutdent;
- (void)heading1;
- (void)heading2;
- (void)heading3;
- (void)heading4;
- (void)heading5;
- (void)heading6;

@end
