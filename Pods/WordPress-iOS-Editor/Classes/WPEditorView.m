#import "WPEditorView.h"

#import "UIWebView+GUIFixes.h"
#import "HRColorUtil.h"
#import "ZSSTextView.h"

typedef void(^WPEditorViewCallbackParameterProcessingBlock)(NSString* parameterName, NSString* parameterValue);
typedef void(^WPEditorViewNoParamsCompletionBlock)();

static NSString* const kDefaultCallbackParameterSeparator = @",";
static NSString* const kDefaultCallbackParameterComponentSeparator = @"=";

@interface WPEditorView () <UITextViewDelegate, UIWebViewDelegate>

#pragma mark - Misc state
@property (nonatomic, assign, readwrite, getter = isShowingPlaceholder) BOOL showingPlaceholder;

#pragma mark - Editing state
@property (nonatomic, assign, readwrite, getter = isEditing) BOOL editing;

#pragma mark - Selection
@property (nonatomic, strong, readwrite) NSString *selectedLinkURL;
@property (nonatomic, strong, readwrite) NSString *selectedLinkTitle;
@property (nonatomic, strong, readwrite) NSString *selectedImageURL;
@property (nonatomic, strong, readwrite) NSString *selectedImageAlt;

#pragma mark - Subviews
@property (nonatomic, strong, readwrite) ZSSTextView *sourceView;
@property (nonatomic, strong, readonly) UIWebView* webView;

#pragma mark - Operation queues
@property (nonatomic, strong, readwrite) NSOperationQueue* editorInteractionQueue;

#pragma mark - Editor loading support
@property (nonatomic, copy, readwrite) NSString* preloadedHTML;
@property (atomic, assign, readwrite) BOOL resourcesLoaded;

@end

@implementation WPEditorView

#pragma mark - NSObject

- (void)dealloc
{
	[self stopObservingKeyboardNotifications];
}

#pragma mark - UIView

- (instancetype)initWithFrame:(CGRect)frame
{
	self = [super initWithFrame:frame];
	
	if (self) {
		CGRect childFrame = frame;
		childFrame.origin = CGPointZero;
		
		[self createSourceViewWithFrame:childFrame];
		[self createWebViewWithFrame:childFrame];
		[self setupHTMLEditor];
	}
	
	return self;
}

#pragma mark - Init helpers

- (void)createSourceViewWithFrame:(CGRect)frame
{
	NSAssert(!_sourceView, @"The source view must not exist when this method is called!");
	
	_sourceView = [[ZSSTextView alloc] initWithFrame:frame];
	_sourceView.hidden = YES;
	_sourceView.autocapitalizationType = UITextAutocapitalizationTypeNone;
	_sourceView.autocorrectionType = UITextAutocorrectionTypeNo;
	_sourceView.autoresizingMask =  UIViewAutoresizingFlexibleHeight;
	_sourceView.autoresizesSubviews = YES;
	_sourceView.delegate = self;
	
	[self addSubview:_sourceView];
}

- (void)createWebViewWithFrame:(CGRect)frame
{
	NSAssert(!_webView, @"The web view must not exist when this method is called!");
	
	_webView = [[UIWebView alloc] initWithFrame:frame];
	_webView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
	_webView.delegate = self;
	_webView.scalesPageToFit = YES;
	_webView.dataDetectorTypes = UIDataDetectorTypeNone;
	_webView.scrollView.bounces = NO;
	
	[self addSubview:_webView];
}

- (void)setupHTMLEditor
{
	NSAssert(!_resourcesLoaded,
			 @"This method is meant to be called only once, to load resources.");
	
	_editorInteractionQueue = [[NSOperationQueue alloc] init];
	
	__block NSString* htmlEditor = nil;
	__weak typeof(self) weakSelf = self;
	
	NSBlockOperation* loadEditorOperation = [NSBlockOperation blockOperationWithBlock:^{
		htmlEditor = [self editorHTML];
	}];
	
    NSBlockOperation* editorDidLoadOperation = [NSBlockOperation blockOperationWithBlock:^{
        __strong typeof(weakSelf) strongSelf = weakSelf;

        if (strongSelf) {
            NSURL* const kBaseURL = [NSURL URLWithString:@"http://"];
            
            [strongSelf.webView loadHTMLString:htmlEditor baseURL:kBaseURL];
        }
    }];
	
	[loadEditorOperation setCompletionBlock:^{
		
		[[NSOperationQueue mainQueue] addOperation:editorDidLoadOperation];
	}];
	
	[_editorInteractionQueue addOperation:loadEditorOperation];
}

- (NSString*)editorHTML
{
	NSString *filePath = [[NSBundle mainBundle] pathForResource:@"editor" ofType:@"html"];
	NSData *htmlData = [NSData dataWithContentsOfFile:filePath];
	NSString *htmlString = [[NSString alloc] initWithData:htmlData encoding:NSUTF8StringEncoding];
	NSString *jQueryMobileEventsPath = [[NSBundle mainBundle] pathForResource:@"jquery.mobile-events.min" ofType:@"js"];
	NSString *jQueryMobileEvents = [[NSString alloc] initWithData:[NSData dataWithContentsOfFile:jQueryMobileEventsPath] encoding:NSUTF8StringEncoding];
	NSString *source = [[NSBundle mainBundle] pathForResource:@"ZSSRichTextEditor" ofType:@"js"];
	NSString *jsString = [[NSString alloc] initWithData:[NSData dataWithContentsOfFile:source] encoding:NSUTF8StringEncoding];
	htmlString = [htmlString stringByReplacingOccurrencesOfString:@"<!--jquery-mobile-events-->" withString:jQueryMobileEvents];
	htmlString = [htmlString stringByReplacingOccurrencesOfString:@"<!--editor-->" withString:jsString];
	
	return htmlString;
}

- (void)willMoveToSuperview:(UIView *)newSuperview
{
	if (!newSuperview) {
		[self stopObservingKeyboardNotifications];
	} else {
		[self startObservingKeyboardNotifications];
	}
}

#pragma mark - UIWebViewDelegate

-            (BOOL)webView:(UIWebView *)webView
shouldStartLoadWithRequest:(NSURLRequest *)request
			navigationType:(UIWebViewNavigationType)navigationType
{
	NSURL *url = [request URL];
	
	BOOL shouldLoad = NO;
	
	if (navigationType != UIWebViewNavigationTypeLinkClicked) {
		BOOL handled = [self handleWebViewCallbackURL:url];
		shouldLoad = !handled;
	}

	return shouldLoad;
}

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
	if ([self.delegate respondsToSelector:@selector(editorViewDidFinishLoading:)]) {
		[self.delegate editorViewDidFinishLoading:self];
	}
}

#pragma mark - Handling callbacks

/**
 *	@brief		Handles UIWebView callbacks.
 *
 *	@param		url		The url for the callback.  Cannot be nil.
 *
 *	@returns	YES if the callback was handled, NO otherwise.
 */
- (BOOL)handleWebViewCallbackURL:(NSURL*)url
{
	NSParameterAssert([url isKindOfClass:[NSURL class]]);

	BOOL handled = NO;

	NSString *scheme = [url scheme];
	
	NSLog(@"WebEditor callback received: %@", url);
	
    if (scheme) {
        if ([self isFocusInScheme:scheme]){
            [self handleFocusInCallback:url];
            handled = YES;
        } else if ([self isFocusOutScheme:scheme]){
            [self handleFocusOutCallback:url];
            handled = YES;
        } else if ([self isInputCallbackScheme:scheme]) {
            [self handleInputCallback:url];
            handled = YES;
        } else if ([self isLinkTappedScheme:scheme]) {
            [self handleLinkTappedCallback:url];
            handled = YES;
        } else if ([self isSelectionStyleScheme:scheme]) {
            [self handleSelectionStyleCallback:url];
            handled = YES;
        } else if ([self isDOMLoadedScheme:scheme]) {
            [self handleDOMLoadedCallback:url];
            handled = YES;
        }
    }
	
	return handled;
}

/**
 *	@brief		Handles a DOM loaded callback.
 *
 *	@param		url		The url with all the callback information.
 */
- (void)handleDOMLoadedCallback:(NSURL*)url
{
    NSParameterAssert([url isKindOfClass:[NSURL class]]);
    
    self.resourcesLoaded = YES;
    self.editorInteractionQueue = nil;
    
    // DRM: it's important to call this after resourcesLoaded has been set to YES.
    [self setHtml:self.preloadedHTML];
    [self setPlaceholderHTMLStringInJavascript];
    [self setPlaceholderHTMLStringColorInJavascript];
    
    if ([self.delegate respondsToSelector:@selector(editorViewDidFinishLoadingDOM:)]) {
        [self.delegate editorViewDidFinishLoadingDOM:self];
    }
}

- (void)handleFocusInCallback:(NSURL*)url
{
    NSParameterAssert([url isKindOfClass:[NSURL class]]);
    
    [self callDelegateFocusChanged:YES];
}

/**
 *	@brief		Handles a focus out callback.
 *
 *	@param		url		The url with all the callback information.
 */
- (void)handleFocusOutCallback:(NSURL*)url
{
    NSParameterAssert([url isKindOfClass:[NSURL class]]);
    
    [self callDelegateFocusChanged:NO];
}

/**
 *	@brief		Handles a key pressed callback.
 *
 *	@param		url		The url with all the callback information.
 */
- (void)handleInputCallback:(NSURL*)url
{
    NSParameterAssert([url isKindOfClass:[NSURL class]]);
    
    [self callDelegateEditorTextDidChange];
}

/**
 *	@brief		Handles a link tapped callback.
 *
 *	@param		url		The url with all the callback information.
 */
- (void)handleLinkTappedCallback:(NSURL*)url
{
	NSParameterAssert([url isKindOfClass:[NSURL class]]);
	
	static NSString* const kTappedUrlParameterName = @"url";
	static NSString* const kTappedUrlTitleParameterName = @"title";
	
	__block NSURL* tappedUrl = nil;
	__block NSString* tappedUrlTitle = nil;
	
	[self parseParametersFromCallbackURL:url
		 andExecuteBlockForEachParameter:^(NSString *parameterName, NSString *parameterValue)
	{
		if ([parameterName isEqualToString:kTappedUrlParameterName]) {
			tappedUrl = [NSURL URLWithString:[self stringByDecodingURLFormat:parameterValue]];
		} else if ([parameterName isEqualToString:kTappedUrlTitleParameterName]) {
			tappedUrlTitle = [self stringByDecodingURLFormat:parameterValue];
		}
	} onComplete:^{
		
		[self saveSelection];
		
		if ([self.delegate respondsToSelector:@selector(editorView:linkTapped:title:)]) {
			[self.delegate editorView:self linkTapped:tappedUrl title:tappedUrlTitle];
		}
	}];
}

- (void)handleSelectionStyleCallback:(NSURL*)url
{
    NSParameterAssert([url isKindOfClass:[NSURL class]]);
    
    NSString* styles = [[url resourceSpecifier] stringByReplacingOccurrencesOfString:@"//" withString:@""];
    
    [self processStyles:styles];
}


- (BOOL)isDOMLoadedScheme:(NSString*)scheme
{
	static NSString* const kCallbackScheme = @"callback-dom-loaded";
	
	return [scheme isEqualToString:kCallbackScheme];
}

- (BOOL)isFocusInScheme:(NSString*)scheme
{
	static NSString* const kCallbackScheme = @"callback-focus-in";
	
	return [scheme isEqualToString:kCallbackScheme];
}

- (BOOL)isFocusOutScheme:(NSString*)scheme
{
	static NSString* const kCallbackScheme = @"callback-focus-out";
	
	return [scheme isEqualToString:kCallbackScheme];
}

- (BOOL)isLinkTappedScheme:(NSString*)scheme
{
    NSAssert([scheme isKindOfClass:[NSString class]],
             @"We're expecting a non-nil string object here.");
    
	static NSString* const kCallbackScheme = @"callback-link-tap";
	
	return [scheme isEqualToString:kCallbackScheme];
}

- (BOOL)isSelectionStyleScheme:(NSString*)scheme
{
	static NSString* const kCallbackScheme = @"callback-selection-style";

	return [scheme isEqualToString:kCallbackScheme];
}

- (BOOL)isInputCallbackScheme:(NSString*)scheme
{
	static NSString* const kCallbackScheme = @"callback-input";
	
	return [scheme isEqualToString:kCallbackScheme];
}

- (void)processStyles:(NSString *)styles
{
    NSArray *styleStrings = [styles componentsSeparatedByString:kDefaultCallbackParameterSeparator];
    NSMutableArray *itemsModified = [[NSMutableArray alloc] init];
	
	self.selectedImageURL = nil;
	self.selectedImageAlt = nil;
	self.selectedLinkURL = nil;
	self.selectedLinkTitle = nil;
	
    for (NSString *styleString in styleStrings) {
        NSString *updatedItem = styleString;
        if ([styleString hasPrefix:@"link:"]) {
            updatedItem = @"link";
            self.selectedLinkURL = [self stringByDecodingURLFormat:[styleString stringByReplacingOccurrencesOfString:@"link:" withString:@""]];
        } else if ([styleString hasPrefix:@"link-title:"]) {
            self.selectedLinkTitle = [self stringByDecodingURLFormat:[styleString stringByReplacingOccurrencesOfString:@"link-title:" withString:@""]];
        } else if ([styleString hasPrefix:@"image:"]) {
            updatedItem = @"image";
            self.selectedImageURL = [styleString stringByReplacingOccurrencesOfString:@"image:" withString:@""];
        } else if ([styleString hasPrefix:@"image-alt:"]) {
            self.selectedImageAlt = [self stringByDecodingURLFormat:[styleString stringByReplacingOccurrencesOfString:@"image-alt:" withString:@""]];
        }
        [itemsModified addObject:updatedItem];
    }
	
    styleStrings = [NSArray arrayWithArray:itemsModified];
    
	if ([self.delegate respondsToSelector:@selector(editorView:stylesForCurrentSelection:)])
	{
		[self.delegate editorView:self stylesForCurrentSelection:styleStrings];
	}
}

#pragma mark - Callback parsing

/**
 *	@brief		Extract the components that make up a parameter.
 *	@details	Should always be two (for example: 'value=65' would return @['value', '65']).
 *
 *	@param		parameter	The string parameter to parse.  Cannot be nil.
 *
 *	@returns	An array containing each component.
 */
- (NSArray*)componentsFromParameter:(NSString*)parameter
{
	NSParameterAssert([parameter isKindOfClass:[NSString class]]);
	
	NSArray* components = [parameter componentsSeparatedByString:kDefaultCallbackParameterComponentSeparator];
	NSAssert([components count] == 2,
			 @"We're expecting exactly two components here.");
	
	return components;
}

/**
 *	@brief		This is a very helpful method for parsing through a callback's parameters and
 *				performing custom processing when each parameter and value is identified.
 *
 *	@param		url					The callback URL to process.  Cannot be nil.
 *	@param		block				Will be executed one time for each parameter identified by the
 *									parser.  Cannot be nil.
 *	@param		onCompleteBlock		The block to execute when the parsing finishes.  Can be nil.
 */
- (void)parseParametersFromCallbackURL:(NSURL*)url
	   andExecuteBlockForEachParameter:(WPEditorViewCallbackParameterProcessingBlock)block
							onComplete:(WPEditorViewNoParamsCompletionBlock)onCompleteBlock
{
	NSParameterAssert([url isKindOfClass:[NSURL class]]);
	NSParameterAssert(block);
	
	NSArray* parameters = [self parametersFromCallbackURL:url];
	NSAssert([parameters count] == 2,
			 @"We're expecting exactly two parameters here.");
	
	for (NSString* parameter in parameters) {
		NSAssert([parameter isKindOfClass:[NSString class]],
				 @"We're expecting to have a non-nil NSString object here.");
		
		NSArray* components = [self componentsFromParameter:parameter];
		
		block([components objectAtIndex:0], [components objectAtIndex:1]);
	}
	
	if (onCompleteBlock) {
		onCompleteBlock();
	}
}

/**
 *	@brief		Extract the parameters that make up a callback URL.
 *
 *	@param		url		The callback URL to parse.  Cannot be nil.
 *
 *	@returns	An array containing each parameter.
 */
- (NSArray*)parametersFromCallbackURL:(NSURL*)url
{
	NSParameterAssert([url isKindOfClass:[NSURL class]]);
	
	NSArray* parameters = [[url resourceSpecifier] componentsSeparatedByString:kDefaultCallbackParameterSeparator];
	
	return parameters;
}

#pragma mark - URL & HTML utilities

/**
 *  @brief      Adds slashes to the specified HTML string, to prevent injections when calling JS
 *              code.
 *
 *  @param      html        The HTML string to add slashes to.  Cannot be nil.
 *
 *  @returns    The HTML string with the added slashes.
 */
- (NSString *)addSlashes:(NSString *)html
{
    html = [html stringByReplacingOccurrencesOfString:@"\\" withString:@"\\\\"];
    html = [html stringByReplacingOccurrencesOfString:@"\"" withString:@"\\\""];
    html = [html stringByReplacingOccurrencesOfString:@"\r"  withString:@"\\r"];
    html = [html stringByReplacingOccurrencesOfString:@"\n"  withString:@"\\n"];
    
    return html;
}

- (NSString *)stringByDecodingURLFormat:(NSString *)string
{
    NSString *result = [string stringByReplacingOccurrencesOfString:@"+" withString:@" "];
    result = [result stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    return result;
}

#pragma mark - Setters

- (void)setPlaceholderHTMLString:(NSString *)placeholderHTMLString
{    
	if (_placeholderHTMLString != placeholderHTMLString) {
		_placeholderHTMLString = placeholderHTMLString;
		
        if (self.resourcesLoaded) {
            [self setPlaceholderHTMLStringInJavascript];
        }
	}
}

- (void)setPlaceholderHTMLStringInJavascript
{
    NSString* string = [self addSlashes:self.placeholderHTMLString];
    
    string = [NSString stringWithFormat:@"zss_editor.setBodyPlaceholder(\"%@\");", string];
    [self.webView stringByEvaluatingJavaScriptFromString:string];
}

- (void)setPlaceholderHTMLStringColor:(UIColor *)placeholderHTMLStringColor
{
    if (_placeholderHTMLStringColor != placeholderHTMLStringColor) {
        _placeholderHTMLStringColor = placeholderHTMLStringColor;
        
        if (self.resourcesLoaded) {
            [self setPlaceholderHTMLStringColorInJavascript];
        }
    }
}

- (void)setPlaceholderHTMLStringColorInJavascript
{
    int hexColor = HexColorFromUIColor(self.placeholderHTMLStringColor);
    NSString* hexColorStr = [NSString stringWithFormat:@"#%06x", hexColor];
    
    NSString* string = [NSString stringWithFormat:@"zss_editor.setBodyPlaceholderColor(\"%@\");", hexColorStr];
    [self.webView stringByEvaluatingJavaScriptFromString:string];
}

#pragma mark - Interaction

- (void)undo
{
    [self.webView stringByEvaluatingJavaScriptFromString:@"zss_editor.undo();"];
	
    [self callDelegateEditorTextDidChange];
}

- (void)redo
{
    [self.webView stringByEvaluatingJavaScriptFromString:@"zss_editor.redo();"];
	
    [self callDelegateEditorTextDidChange];
}

#pragma mark - Selection

- (void)restoreSelection
{
	[self.webView stringByEvaluatingJavaScriptFromString:@"zss_editor.restoreRange();"];
}

- (void)saveSelection
{
    [self.webView stringByEvaluatingJavaScriptFromString:@"zss_editor.prepareInsert();"];
}

- (NSString*)selectedText
{
	NSString* selectedText = [self.webView stringByEvaluatingJavaScriptFromString:@"zss_editor.getSelectedText();"];
	
	return selectedText;
}

- (void)setSelectedColor:(UIColor*)color tag:(int)tag
{
    NSString *hex = [NSString stringWithFormat:@"#%06x",HexColorFromUIColor(color)];
    NSString *trigger;
    if (tag == 1) {
        trigger = [NSString stringWithFormat:@"zss_editor.setTextColor(\"%@\");", hex];
    } else if (tag == 2) {
        trigger = [NSString stringWithFormat:@"zss_editor.setBackgroundColor(\"%@\");", hex];
    }
	
	[self.webView stringByEvaluatingJavaScriptFromString:trigger];
	
    [self callDelegateEditorTextDidChange];
}

#pragma mark - Images

- (void)insertImage:(NSString *)url alt:(NSString *)alt
{
    NSString *trigger = [NSString stringWithFormat:@"zss_editor.insertImage(\"%@\", \"%@\");", url, alt];
    [self.webView stringByEvaluatingJavaScriptFromString:trigger];
}

- (void)updateImage:(NSString *)url alt:(NSString *)alt
{
    NSString *trigger = [NSString stringWithFormat:@"zss_editor.updateImage(\"%@\", \"%@\");", url, alt];
    [self.webView stringByEvaluatingJavaScriptFromString:trigger];
}

#pragma mark - Links

- (void)insertLink:(NSString *)url
			 title:(NSString*)title
{
	NSParameterAssert([url isKindOfClass:[NSString class]]);
	NSParameterAssert([title isKindOfClass:[NSString class]]);
	
	NSString *trigger = [NSString stringWithFormat:@"zss_editor.insertLink(\"%@\",\"%@\");", url, title];
	[self.webView stringByEvaluatingJavaScriptFromString:trigger];
	
    [self callDelegateEditorTextDidChange];
}

- (BOOL)isSelectionALink
{
	return self.selectedLinkURL != nil;
}

- (void)updateLink:(NSString *)url
			 title:(NSString*)title
{
	NSParameterAssert([url isKindOfClass:[NSString class]]);
	NSParameterAssert([title isKindOfClass:[NSString class]]);
	
	NSString *trigger = [NSString stringWithFormat:@"zss_editor.updateLink(\"%@\",\"%@\");", url, title];
	[self.webView stringByEvaluatingJavaScriptFromString:trigger];
	
    [self callDelegateEditorTextDidChange];
}

- (void)removeLink
{
	[self.webView stringByEvaluatingJavaScriptFromString:@"zss_editor.unlink();"];
}

- (void)quickLink
{
	[self.webView stringByEvaluatingJavaScriptFromString:@"zss_editor.quickLink();"];
}

#pragma mark - Editor: HTML interaction

/**
 *	@brief		Call this method to know if the editor has no content.
 *
 *	@returns	YES if the editor has no content.
 */
- (BOOL)isBodyEmpty
{
    NSString* html = [self getHTML];
    
    BOOL isEmpty = [html length] == 0 || [html isEqualToString:@"<br>"];
    
    return isEmpty;
}

- (void)setHtml:(NSString *)html
{
	if (!self.resourcesLoaded) {
		self.preloadedHTML = html;
	} else {
		self.sourceView.text = html;
		NSString *cleanedHTML = [self addSlashes:self.sourceView.text];
		NSString *trigger = [NSString stringWithFormat:@"zss_editor.setHTML(\"%@\");", cleanedHTML];
		[self.webView stringByEvaluatingJavaScriptFromString:trigger];
	}
}

// Inserts HTML at the caret position
- (void)insertHTML:(NSString *)html
{
    NSString *cleanedHTML = [self addSlashes:html];
    NSString *trigger = [NSString stringWithFormat:@"zss_editor.insertHTML(\"%@\");", cleanedHTML];
    [self.webView stringByEvaluatingJavaScriptFromString:trigger];
}

- (NSString *)getHTML
{
    NSString *html = nil;
    
    if (!self.isShowingPlaceholder) {
        html = [self.webView stringByEvaluatingJavaScriptFromString:@"zss_editor.getHTML();"];
    }
    
	return html;
}

#pragma mark - Editor focus

- (void)focus
{
    self.webView.keyboardDisplayRequiresUserAction = NO;
    NSString *js = [NSString stringWithFormat:@"zss_editor.focusEditor();"];
    [self.webView stringByEvaluatingJavaScriptFromString:js];
}

- (void)blur
{
    NSString *js = [NSString stringWithFormat:@"zss_editor.blurEditor();"];
    [self.webView stringByEvaluatingJavaScriptFromString:js];
}

- (void)endEditing;
{
	[self.webView endEditing:YES];
	[self.sourceView endEditing:YES];
}

#pragma mark - Editor mode

- (BOOL)isInVisualMode
{
	return !self.webView.hidden;
}

- (void)showHTMLSource
{
	self.sourceView.text = [self getHTML];
	self.sourceView.hidden = NO;
	self.webView.hidden = YES;
}

- (void)showVisualEditor
{
	[self setHtml:self.sourceView.text];
	self.sourceView.hidden = YES;
	self.webView.hidden = NO;
}

#pragma mark - Editing lock

- (void)disableEditing
{
	NSString *js = [NSString stringWithFormat:@"zss_editor.disableEditing();"];
	[self.webView stringByEvaluatingJavaScriptFromString:js];
}

- (void)enableEditing
{
	NSString *js = [NSString stringWithFormat:@"zss_editor.enableEditing();"];
	[self.webView stringByEvaluatingJavaScriptFromString:js];
}

#pragma mark - Customization

- (void)setInputAccessoryView:(UIView*)inputAccessoryView
{
	self.webView.usesGUIFixes = YES;
	self.webView.customInputAccessoryView = inputAccessoryView;
	self.sourceView.inputAccessoryView = inputAccessoryView;
}

#pragma mark - Styles

- (void)alignLeft
{
    NSString *trigger = @"zss_editor.setJustifyLeft();";
	[self.webView stringByEvaluatingJavaScriptFromString:trigger];
    
    [self callDelegateEditorTextDidChange];
}

- (void)alignCenter
{
    NSString *trigger = @"zss_editor.setJustifyCenter();";
	[self.webView stringByEvaluatingJavaScriptFromString:trigger];

    [self callDelegateEditorTextDidChange];
}

- (void)alignRight
{
    NSString *trigger = @"zss_editor.setJustifyRight();";
	[self.webView stringByEvaluatingJavaScriptFromString:trigger];

    [self callDelegateEditorTextDidChange];
}

- (void)alignFull
{
    NSString *trigger = @"zss_editor.setJustifyFull();";
	[self.webView stringByEvaluatingJavaScriptFromString:trigger];

    [self callDelegateEditorTextDidChange];
}

- (void)setBold
{
    NSString *trigger = @"zss_editor.setBold();";
	[self.webView stringByEvaluatingJavaScriptFromString:trigger];

    [self callDelegateEditorTextDidChange];
}

- (void)setBlockQuote
{
    NSString *trigger = @"zss_editor.setBlockquote();";
	[self.webView stringByEvaluatingJavaScriptFromString:trigger];

    [self callDelegateEditorTextDidChange];
}

- (void)setItalic
{
    NSString *trigger = @"zss_editor.setItalic();";
	[self.webView stringByEvaluatingJavaScriptFromString:trigger];

    [self callDelegateEditorTextDidChange];
}

- (void)setSubscript
{
    NSString *trigger = @"zss_editor.setSubscript();";
	[self.webView stringByEvaluatingJavaScriptFromString:trigger];

    [self callDelegateEditorTextDidChange];
}

- (void)setUnderline
{
    NSString *trigger = @"zss_editor.setUnderline();";
	[self.webView stringByEvaluatingJavaScriptFromString:trigger];

    [self callDelegateEditorTextDidChange];
}

- (void)setSuperscript
{
    NSString *trigger = @"zss_editor.setSuperscript();";
	[self.webView stringByEvaluatingJavaScriptFromString:trigger];

    [self callDelegateEditorTextDidChange];
}

- (void)setStrikethrough
{
    NSString *trigger = @"zss_editor.setStrikeThrough();";
	[self.webView stringByEvaluatingJavaScriptFromString:trigger];

    [self callDelegateEditorTextDidChange];
}

- (void)setUnorderedList
{
    NSString *trigger = @"zss_editor.setUnorderedList();";
	[self.webView stringByEvaluatingJavaScriptFromString:trigger];

    [self callDelegateEditorTextDidChange];
}

- (void)setOrderedList
{
    NSString *trigger = @"zss_editor.setOrderedList();";
	[self.webView stringByEvaluatingJavaScriptFromString:trigger];

    [self callDelegateEditorTextDidChange];
}

- (void)setHR
{
    NSString *trigger = @"zss_editor.setHorizontalRule();";
	[self.webView stringByEvaluatingJavaScriptFromString:trigger];

    [self callDelegateEditorTextDidChange];
}

- (void)setIndent
{
    NSString *trigger = @"zss_editor.setIndent();";
	[self.webView stringByEvaluatingJavaScriptFromString:trigger];

    [self callDelegateEditorTextDidChange];
}

- (void)setOutdent
{
    NSString *trigger = @"zss_editor.setOutdent();";
	[self.webView stringByEvaluatingJavaScriptFromString:trigger];

    [self callDelegateEditorTextDidChange];
}

- (void)heading1
{
    NSString *trigger = @"zss_editor.setHeading('h1');";
	[self.webView stringByEvaluatingJavaScriptFromString:trigger];

    [self callDelegateEditorTextDidChange];
}

- (void)heading2
{
    NSString *trigger = @"zss_editor.setHeading('h2');";
	[self.webView stringByEvaluatingJavaScriptFromString:trigger];

    [self callDelegateEditorTextDidChange];
}

- (void)heading3
{
    NSString *trigger = @"zss_editor.setHeading('h3');";
	[self.webView stringByEvaluatingJavaScriptFromString:trigger];

    [self callDelegateEditorTextDidChange];
}

- (void)heading4
{
    NSString *trigger = @"zss_editor.setHeading('h4');";
	[self.webView stringByEvaluatingJavaScriptFromString:trigger];

    [self callDelegateEditorTextDidChange];
}

- (void)heading5
{
    NSString *trigger = @"zss_editor.setHeading('h5');";
	[self.webView stringByEvaluatingJavaScriptFromString:trigger];

    [self callDelegateEditorTextDidChange];
}

- (void)heading6
{
    NSString *trigger = @"zss_editor.setHeading('h6');";
	[self.webView stringByEvaluatingJavaScriptFromString:trigger];

    [self callDelegateEditorTextDidChange];
}


- (void)removeFormat
{
    NSString *trigger = @"zss_editor.removeFormating();";
	[self.webView stringByEvaluatingJavaScriptFromString:trigger];

    [self callDelegateEditorTextDidChange];
}

#pragma mark - Keyboard notifications

- (void)startObservingKeyboardNotifications
{
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(keyboardWillShow:)
												 name:UIKeyboardWillShowNotification
											   object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(keyboardWillHide:)
												 name:UIKeyboardWillHideNotification
											   object:nil];
}

- (void)stopObservingKeyboardNotifications
{
	[[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
	[[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
}


#pragma mark - Keyboard status

- (void)keyboardWillShow:(NSNotification *)notification
{
	NSDictionary *info = notification.userInfo;
	CGRect keyboardEnd = [[info objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
	
	CGRect localizedKeyboardEnd = [self convertRect:keyboardEnd fromView:nil];
	CGPoint keyboardOrigin = localizedKeyboardEnd.origin;
	
	if (keyboardOrigin.y > 0) {
		
		CGFloat vOffset = self.frame.size.height - keyboardOrigin.y;
		
		UIEdgeInsets webViewInsets = self.webView.scrollView.contentInset;
		webViewInsets.bottom = vOffset;
		self.webView.scrollView.contentInset = webViewInsets;
		self.webView.scrollView.scrollIndicatorInsets = webViewInsets;
		
		UIEdgeInsets sourceViewInsets = self.webView.scrollView.contentInset;
		sourceViewInsets.bottom = vOffset;
		self.sourceView.contentInset = sourceViewInsets;
		self.sourceView.scrollIndicatorInsets = sourceViewInsets;
	}
}

- (void)keyboardWillHide:(NSNotification *)notification
{
	self.webView.scrollView.contentInset = UIEdgeInsetsZero;
	self.webView.scrollView.scrollIndicatorInsets = UIEdgeInsetsZero;
	self.sourceView.contentInset = UIEdgeInsetsZero;
	self.sourceView.scrollIndicatorInsets = UIEdgeInsetsZero;
}

#pragma mark - Delegate calls

/**
 *  @brief      Call's the delegate editorTextDidChange: method.
 */
- (void)callDelegateEditorTextDidChange
{
    if ([self.delegate respondsToSelector: @selector(editorTextDidChange:)]) {
        [self.delegate editorTextDidChange:self];
    }
}

/**
 *  @brief      Call's the delegate editorView:focusChanged: method.
 */
- (void)callDelegateFocusChanged:(BOOL)focusGained
{
    if ([self.delegate respondsToSelector:@selector(editorView:focusChanged:)]) {
        [self.delegate editorView:self focusChanged:focusGained];
    }
}

@end
