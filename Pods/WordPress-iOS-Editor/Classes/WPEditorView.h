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

/**
 *	@brief		The editor's delegate.
 */
@property (nonatomic, weak, readwrite) id<WPEditorViewDelegate> delegate;

/**
 *	@brief		Stores the current edit mode state for this view.
 */
@property (nonatomic, assign, readonly, getter = isEditing) BOOL editing;

/**
 *	@brief		The placeholder HTML string to show when the editor view is empty in visual mode.
 */
@property (nonatomic, copy, readwrite) NSString* placeholderHTMLString;

#pragma mark - Selection
@property (nonatomic, strong, readonly) NSString *selectedLinkURL;

#pragma mark - Interaction

- (void)setHtml:(NSString *)html;
- (void)insertHTML:(NSString *)html;
- (NSString *)getHTML;

/**
 *	@brief		Undo the last operation.
 */
- (void)undo;

/**
 *	@brief		Redo the last operation.
 */
- (void)redo;

/**
 *	@brief		Saves the current text selection.
 *	@details	The selection is restored automatically by some insert operations when called.
 *				The only important step is to call this method before an insertion of a link or
 *				image.
 */
- (void)saveSelection;

/**
 *	@brief		Inserts a link at the last saved selection.
 *
 *	@param		url		The url that will open when the link is clicked.
 *	@param		title	The title for the link.
 */
- (void)insertLink:(NSString *)url
			 title:(NSString *)title;

/**
 *	@brief		Updates the link at the last saved selection.
 *
 *	@param		url		The url that will open when the link is clicked.
 *	@param		title	The title for the link.
 */
- (void)updateLink:(NSString *)url
			 title:(NSString *)title;

- (void)setSelectedColor:(UIColor*)color
					 tag:(int)tag;
- (void)removeLink;
- (void)quickLink;
- (void)insertImage:(NSString *)url alt:(NSString *)alt;
- (void)updateImage:(NSString *)url alt:(NSString *)alt;

#pragma mark - Editor focus

/**
 *	@brief		Assigns focus to the editor.
 *	@todo		DRM: Replace this with becomeFirstResponder????
 */
- (void)focus;

/**
 *	@brief		Resigns focus from the editor.
 *	@todo		DRM: Replace this with resignFirstResponder????
 */
- (void)blur;

/**
 *	@brief		Ends editing and forces any subview to resign first responder.
 */
- (void)endEditing;

#pragma mark - Editor mode

- (BOOL)isInVisualMode;
- (void)showHTMLSource;
- (void)showVisualEditor;

#pragma mark - Editing lock

/**
 *	@brief		Disables editing.
 */
- (void)disableEditing;

/**
 *	@brief		Enables editing.
 */
- (void)enableEditing;

#pragma mark - Customization

/**
 *	@brief		Sets the input accessory view for the editor.
 */
- (void)setInputAccessoryView:(UIView*)inputAccessoryView;

#pragma mark - Styles

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
- (void)removeFormat;

@end
