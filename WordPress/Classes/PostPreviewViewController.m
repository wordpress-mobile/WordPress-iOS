#import <QuartzCore/QuartzCore.h>
#import "PostPreviewViewController.h"
#import "WordPressAppDelegate.h"
#import "NSString+Helpers.h"
#import "EditPostViewController_Internal.h"
#import "Post.h"

@interface PostPreviewViewController ()
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
    [super didReceiveMemoryWarning]; // Releases the view if it doesn't have a superview
    // Release anything that's not essential, such as cached data
}


- (void)viewDidLoad {
    [super viewDidLoad];
    DDLogInfo(@"%@ %@", self, NSStringFromSelector(_cmd));
	self.webView.delegate = self;
	if (loadingView == nil) {
        
        CGRect frame = self.view.frame;
        CGFloat sides = 100.0f;
        CGFloat x = (frame.size.width / 2.0f) - (sides / 2.0f);
        CGFloat y = (frame.size.height / 2.0f) - (sides / 2.0f);

        loadingView = [[UIView alloc] initWithFrame:CGRectMake(x, y, sides, sides)];
        loadingView.layer.cornerRadius = 10.0f;
        loadingView.backgroundColor = [UIColor colorWithWhite:0.0f alpha:0.8f];
        loadingView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin |
                                       UIViewAutoresizingFlexibleBottomMargin |
                                       UIViewAutoresizingFlexibleTopMargin |
                                       UIViewAutoresizingFlexibleRightMargin;
        
        UIActivityIndicatorView *activityView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
        activityView.hidesWhenStopped = NO;
        activityView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin |
                                        UIViewAutoresizingFlexibleBottomMargin |
                                        UIViewAutoresizingFlexibleTopMargin |
                                        UIViewAutoresizingFlexibleRightMargin;
        [activityView startAnimating];
        
        CGRect frm = activityView.frame;
        frm.origin.x = (sides / 2.0f) - (frm.size.width / 2.0f);
        frm.origin.y = (sides / 2.0f) - (frm.size.height / 2.0f);
        activityView.frame = frm;
        [loadingView addSubview:activityView];
    }
	
    [self.view addSubview:loadingView];
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


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return [super shouldAutorotateToInterfaceOrientation:interfaceOrientation];
}


#pragma mark -
#pragma mark Instance Methods

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
		if (!desc)
			desc = [NSString stringWithFormat:@"<h1>%@</h1>", NSLocalizedString(@"No Description available for this Post", @"")];
        else {
				desc = [self stringReplacingNewlinesWithBR:desc];
			}
		desc = [NSString stringWithFormat:@"<p>%@</p><br />", desc];
		str = [str stringByReplacingOccurrencesOfString:@"!$text$!" withString:desc];
		
		//Tags
		NSString *tags = self.post.tags;
		tags = (tags == nil ? @"" : tags);
		tags = [NSString stringWithFormat:NSLocalizedString(@"Tags: %@", @""), tags]; //desc = [NSString stringWithFormat:@"%@ \n <p>Tags: %@</p><br>", desc, tags];
		str = [str stringByReplacingOccurrencesOfString:@"!$mt_keywords$!" withString:tags];
		
		//Categories [selObjects count]
		NSArray *categories = [self.post.categories allObjects];
		NSString *catStr = @"";
		int i = 0, count = [categories count];
		for (i = 0; i < count; i++) {
			Category *category = [categories objectAtIndex:i];
			catStr = [catStr stringByAppendingString:category.categoryName];
			if(i < count-1)
				catStr = [catStr stringByAppendingString:@", "];
		}
		catStr = [NSString stringWithFormat:NSLocalizedString(@"Categories: %@", @""), catStr]; //desc = [NSString stringWithFormat:@"%@ \n <p>Categories: %@</p><br>", desc, catStr];
		str = [str stringByReplacingOccurrencesOfString:@"!$categories$!" withString:catStr];

	} else {
		str = @"";
	}
		
	return str;
}

- (void)showSimplePreviewWithMessage:(NSString *)message {
    WPFLogMethod();
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
    NSDate *laterDate = self.apost.date_created_gmt;

	if ([status isEqualToString:@"draft"])
		needsLogin = YES;
	else if ([status isEqualToString:@"private"])
		needsLogin = YES;
	else if ([status isEqualToString:@"pending"])
		needsLogin = YES;
    else if ([self.apost.blog isPrivate])
        needsLogin = YES; // Private blog
    else if ([laterDate isEqualToDate:postGMTDate])
        needsLogin = YES; // Scheduled post

    NSString *link = self.apost.original.permaLink;

    WordPressAppDelegate  *appDelegate = (WordPressAppDelegate *)[[UIApplication sharedApplication] delegate];

    if( appDelegate.connectionAvailable == NO ) {
        [self showSimplePreviewWithMessage:[NSString stringWithFormat:@"<div class=\"page\"><p>%@ %@</p>", NSLocalizedString(@"The internet connection appears to be offline.", @""), NSLocalizedString(@"A simple preview is shown below.", @"")]];
    } else if ( self.apost.blog.reachable == NO ) {
        [self showSimplePreviewWithMessage:[NSString stringWithFormat:@"<div class=\"page\"><p>%@ %@</p>", NSLocalizedString(@"The internet connection cannot reach your blog.", @""), NSLocalizedString(@"A simple preview is shown below.", @"")]];
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
	BOOL edited = [self.apost hasChanges];
    loadingView.hidden = NO;

	if (edited) {
        [self showSimplePreview];
	} else {
		[self showRealPreview];
	}
}

- (void)webViewDidStartLoad:(UIWebView *)webView {
    WPFLogMethod();
    loadingView.hidden = NO;
}

- (void)webViewDidFinishLoad:(UIWebView *)awebView {
    WPFLogMethod();
    loadingView.hidden = YES;
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error
{
    WPFLogMethodParam(error);
    loadingView.hidden = YES;
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