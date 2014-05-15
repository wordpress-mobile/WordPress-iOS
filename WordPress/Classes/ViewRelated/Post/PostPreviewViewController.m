#import "PostPreviewViewController.h"
#import "WordPressAppDelegate.h"
#import "NSString+Helpers.h"
#import "EditPostViewController_Internal.h"
#import "Post.h"

@interface PostPreviewViewController ()

@property (nonatomic, strong) UIWebView *webView;
@property (nonatomic, strong) UIView *loadingView;
@property (nonatomic, strong) NSMutableData *receivedData;
@property (nonatomic, strong) AbstractPost *apost;

@end

@implementation PostPreviewViewController

#pragma mark -
#pragma mark Lifecycle Methods

- (void)dealloc {
    [[WordPressAppDelegate sharedWordPressApplicationDelegate] useAppUserAgent];
	[self.webView stopLoading];
	self.webView.delegate = nil;
}

- (id)initWithPost:(AbstractPost *)aPost {
    self = [super init];
    if (self) {
        self.apost = aPost;
        self.navigationItem.title = NSLocalizedString(@"Preview", @"Post Editor / Preview screen title.");
    }
    return self;
}

- (void)didReceiveMemoryWarning {
    DDLogWarn(@"%@ %@", self, NSStringFromSelector(_cmd));
    [super didReceiveMemoryWarning];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    DDLogInfo(@"%@ %@", self, NSStringFromSelector(_cmd));
    [self setupWebView];
    [self setupLoadingView];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [[WordPressAppDelegate sharedWordPressApplicationDelegate] useDefaultUserAgent];
    [self refreshWebView];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [[WordPressAppDelegate sharedWordPressApplicationDelegate] useAppUserAgent];
	[self.webView stopLoading];
}

#pragma mark -
#pragma mark Instance Methods

- (void)setupWebView {
    if (!self.webView) {
        self.webView = [[UIWebView alloc] initWithFrame:self.view.bounds];
        self.webView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        self.webView.delegate = self;
    }
    [self.view addSubview:self.webView];
}

- (void)setupLoadingView {
	if (!self.loadingView) {
        
        CGRect frame = self.view.frame;
        CGFloat sides = 100.0f;
        CGFloat x = (frame.size.width - sides) / 2.0f;
        CGFloat y = (frame.size.height - sides) / 2.0f;
        
        self.loadingView = [[UIView alloc] initWithFrame:CGRectMake(x, y, sides, sides)];
        self.loadingView.layer.cornerRadius = 10.0f;
        self.loadingView.backgroundColor = [UIColor colorWithWhite:0.0f alpha:0.8f];
        self.loadingView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin |
        UIViewAutoresizingFlexibleBottomMargin |
        UIViewAutoresizingFlexibleTopMargin |
        UIViewAutoresizingFlexibleRightMargin;
        
        UIActivityIndicatorView *activityView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
        [activityView startAnimating];
        
        frame = activityView.frame;
        frame.origin.x = (sides - frame.size.width) / 2.0f;
        frame.origin.y = (sides - frame.size.height) / 2.0f;
        activityView.frame = frame;
        [self.loadingView addSubview:activityView];
    }
    
    [self.view addSubview:self.loadingView];
}

- (Post *)post {
    if ([self.apost isKindOfClass:[Post class]]) {
        return (Post *)self.apost;
    } else {
        return nil;
    }
}

- (NSString *)buildSimplePreview {
	NSString *resourcePath = [[NSBundle mainBundle] resourcePath];
	NSString *fpath = [NSString stringWithFormat:@"%@/defaultPostTemplate.html", resourcePath];
	NSString *str = [NSString stringWithContentsOfFile:fpath encoding:NSUTF8StringEncoding error:nil];
	
	if ([str length]) {
		
		//Title
		NSString *title = self.apost.postTitle;
		title = (title == nil || ([title length] == 0) ? NSLocalizedString(@"(no title)", @"") : title);
		str = [str stringByReplacingOccurrencesOfString:@"!$title$!" withString:title];
		
		//Content
		NSString *desc = self.apost.content;
		if (!desc) {
			desc = [NSString stringWithFormat:@"<h1>%@</h1>", NSLocalizedString(@"No Description available for this Post", @"")];
        } else {
            desc = [self stringReplacingNewlinesWithBR:desc];
        }
		desc = [NSString stringWithFormat:@"<p>%@</p><br />", desc];
		str = [str stringByReplacingOccurrencesOfString:@"!$text$!" withString:desc];
		
		//Tags
		NSString *tags = self.post.tags;
		tags = (tags == nil ? @"" : tags);
		tags = [NSString stringWithFormat:NSLocalizedString(@"Tags: %@", @""), tags];
		str = [str stringByReplacingOccurrencesOfString:@"!$mt_keywords$!" withString:tags];
		
		//Categories [selObjects count]
		NSArray *categories = [self.post.categories allObjects];
		NSString *catStr = @"";
		NSUInteger i = 0, count = [categories count];
		for (i = 0; i < count; i++) {
			Category *category = [categories objectAtIndex:i];
			catStr = [catStr stringByAppendingString:category.categoryName];
			if(i < count-1) {
				catStr = [catStr stringByAppendingString:@", "];
            }
		}
		catStr = [NSString stringWithFormat:NSLocalizedString(@"Categories: %@", @""), catStr];
		str = [str stringByReplacingOccurrencesOfString:@"!$categories$!" withString:catStr];

	} else {
		str = @"";
	}
		
	return str;
}

- (void)showSimplePreviewWithMessage:(NSString *)message {
    DDLogMethod();
    NSString *previewPageHTML = [self buildSimplePreview];
    if (message) {
        previewPageHTML = [previewPageHTML stringByReplacingOccurrencesOfString:@"<div class=\"page\">" withString:[NSString stringWithFormat:@"<div class=\"page\"><p>%@</p>", message]];
    }
    [self.webView loadHTMLString:previewPageHTML baseURL:nil];
}

- (void)showSimplePreview {
    [self showSimplePreviewWithMessage:nil];
}

- (void)showRealPreview {
	BOOL needsLogin = NO;
	NSString *status = self.apost.original.status;
    NSDate *postGMTDate = self.apost.date_created_gmt;
    NSDate *laterDate = [self.apost.date_created_gmt laterDate:[NSDate date]];

    if ([status isEqualToString:@"draft"]) {
        needsLogin = YES;
    } else if ([status isEqualToString:@"private"]) {
        needsLogin = YES;
    } else if ([status isEqualToString:@"pending"]) {
        needsLogin = YES;
    } else if ([self.apost.blog isPrivate]) {
        needsLogin = YES; // Private blog
    } else if ([laterDate isEqualToDate:postGMTDate]) {
        needsLogin = YES; // Scheduled post
    }
    
    NSString *link = self.apost.original.permaLink;

    WordPressAppDelegate  *appDelegate = (WordPressAppDelegate *)[[UIApplication sharedApplication] delegate];

    if( appDelegate.connectionAvailable == NO ) {
        [self showSimplePreviewWithMessage:[NSString stringWithFormat:@"<div class=\"page\"><p>%@ %@</p>", NSLocalizedString(@"The internet connection appears to be offline.", @""), NSLocalizedString(@"A simple preview is shown below.", @"")]];
    } else if ( self.apost.blog.reachable == NO ) {
        [self showSimplePreviewWithMessage:[NSString stringWithFormat:@"<div class=\"page\"><p>%@ %@</p>", NSLocalizedString(@"The internet connection cannot reach your site.", @""), NSLocalizedString(@"A simple preview is shown below.", @"")]];
    } else if (link == nil ) {
        [self showSimplePreview];
    } else {
        if(needsLogin) {
            NSString *wpLoginURL = [self.apost.blog loginUrl];
            NSURL *url = [NSURL URLWithString:wpLoginURL];
            NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:url];
            [req setHTTPMethod:@"POST"];
            [req addValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
            NSString *paramDataString = [NSString stringWithFormat:@"%@=%@&%@=%@&%@=%@",
                                         @"log", [self.apost.blog.username stringByUrlEncoding],
                                         @"pwd", [self.apost.blog.password stringByUrlEncoding],
                                         @"redirect_to", [link stringByUrlEncoding]];

            NSData *paramData = [paramDataString dataUsingEncoding:NSUTF8StringEncoding];
            [req setHTTPBody: paramData];
            [req setValue:[NSString stringWithFormat:@"%d", [paramData length]] forHTTPHeaderField:@"Content-Length"];
            [req addValue:@"*/*" forHTTPHeaderField:@"Accept"];
            [self.webView loadRequest:req];
            DDLogInfo(@"Showing real preview (login) for %@", link);
        } else {
            [self.webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:link]]];
            DDLogInfo(@"Showing real preview for %@", link);
        }
    }
}

#pragma mark -
#pragma mark Webkit View Delegate Methods

- (void)refreshWebView {
	BOOL edited = [self.apost hasChanged];
    self.loadingView.hidden = NO;

	if (edited) {
        [self showSimplePreview];
	} else {
		[self showRealPreview];
	}
}

- (void)webViewDidStartLoad:(UIWebView *)webView {
    DDLogMethod();
    self.loadingView.hidden = NO;
}

- (void)webViewDidFinishLoad:(UIWebView *)awebView {
    DDLogMethod();
    self.loadingView.hidden = YES;
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error {
    DDLogMethodParam(error);
    self.loadingView.hidden = YES;
}

- (BOOL)webView:(UIWebView *)awebView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
    if ([[[request URL] query] isEqualToString:@"action=postpass"]) {
        // Password-protected post, user entered password
        return YES;
    }

    if ([[[request URL] absoluteString] isEqualToString:self.apost.original.permaLink]) {
        // Always allow loading the preview
        return YES;
    }

    if (navigationType == UIWebViewNavigationTypeLinkClicked || navigationType == UIWebViewNavigationTypeFormSubmitted) {
        return NO;
    }
    return YES;
}

#pragma mark -

- (NSString *)stringReplacingNewlinesWithBR:(NSString *)surString {
    NSArray *comps = [surString componentsSeparatedByString:@"\n"];
    return [comps componentsJoinedByString:@"<br>"];
}


@end