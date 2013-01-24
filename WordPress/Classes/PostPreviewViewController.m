#import "PostPreviewViewController.h"
#import "WordPressAppDelegate.h"
#import "NSString+Helpers.h"
#import <QuartzCore/QuartzCore.h>

@interface PostPreviewViewController (Private)

- (void)addProgressIndicator;
- (NSString *)stringReplacingNewlinesWithBR:(NSString *)surString;
- (NSString *)buildSimplePreview;

@end

@implementation PostPreviewViewController

@synthesize postDetailViewController, webView;

#pragma mark -
#pragma mark Lifecycle Methods

- (void)dealloc {
    [[WordPressAppDelegate sharedWordPressApplicationDelegate] useAppUserAgent];
	[webView stopLoading];
	webView.delegate = nil;
}


- (void)didReceiveMemoryWarning {
    WPLog(@"%@ %@", self, NSStringFromSelector(_cmd));
    [super didReceiveMemoryWarning]; // Releases the view if it doesn't have a superview
    // Release anything that's not essential, such as cached data
}


- (void)viewDidLoad {
    [super viewDidLoad];
    [FileLogger log:@"%@ %@", self, NSStringFromSelector(_cmd)];
	webView.delegate = self;
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
	[webView stopLoading];
}


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return [super shouldAutorotateToInterfaceOrientation:interfaceOrientation];
}


#pragma mark -
#pragma mark Instance Methods

- (NSString *)buildSimplePreview {
	NSString *resourcePath = [[NSBundle mainBundle] resourcePath];
	NSString *fpath = [NSString stringWithFormat:@"%@/defaultPostTemplate.html", resourcePath];
	NSString *str = [NSString stringWithContentsOfFile:fpath encoding:NSUTF8StringEncoding error:nil];
	
	if ([str length]) {
		
		//Title
		NSString *title = postDetailViewController.apost.postTitle;
		title = (title == nil || ([title length] == 0) ? NSLocalizedString(@"(no title)", @"") : title);
		str = [str stringByReplacingOccurrencesOfString:@"!$title$!" withString:title];
		
		//Content
		NSString *desc = postDetailViewController.apost.content;
		if (!desc)
			desc = [NSString stringWithFormat:@"<h1>%@</h1>", NSLocalizedString(@"No Description available for this Post", @"")];
        else {
				desc = [self stringReplacingNewlinesWithBR:desc];
			}
		desc = [NSString stringWithFormat:@"<p>%@</p><br />", desc];
		str = [str stringByReplacingOccurrencesOfString:@"!$text$!" withString:desc];
		
		//Tags
		NSString *tags = postDetailViewController.post.tags;
		tags = (tags == nil ? @"" : tags);
		tags = [NSString stringWithFormat:NSLocalizedString(@"Tags: %@", @""), tags]; //desc = [NSString stringWithFormat:@"%@ \n <p>Tags: %@</p><br>", desc, tags];
		str = [str stringByReplacingOccurrencesOfString:@"!$mt_keywords$!" withString:tags];
		
		//Categories [selObjects count]
		NSArray *categories = [postDetailViewController.post.categories allObjects];
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

- (void)showRealPreview {
	NSString *status = postDetailViewController.apost.original.status;
	//draft post
	BOOL isDraft = [self.postDetailViewController isAFreshlyCreatedDraft];
	BOOL isPrivate = NO;
	BOOL isPending = NO;
    BOOL isPrivateBlog = [postDetailViewController.apost.blog isPrivate];

	if ([status isEqualToString:@"draft"])
		isDraft = YES;
	else if ([status isEqualToString:@"private"])
		isPrivate = YES;
	else if ([status isEqualToString:@"pending"])
		isPending = YES;

    NSString *link = postDetailViewController.apost.original.permaLink;

    WordPressAppDelegate  *appDelegate = (WordPressAppDelegate *)[[UIApplication sharedApplication] delegate];

    if( appDelegate.connectionAvailable == NO ) {
        NSString *previewPageHTML = [self buildSimplePreview];
        NSString *noConnectionMessageHTML = [NSString stringWithFormat:@"<div class=\"page\"><p>%@ %@</p>", NSLocalizedString(@"The internet connection appears to be offline.", @""), NSLocalizedString(@"A simple preview is shown below.", @"")];
        previewPageHTML = [previewPageHTML stringByReplacingOccurrencesOfString:@"<div class=\"page\">" withString:noConnectionMessageHTML];
        [webView loadHTMLString:previewPageHTML baseURL:nil];
    } else if ( postDetailViewController.apost.blog.reachable == NO ) {
        NSString *previewPageHTML = [self buildSimplePreview];
        NSString *noConnectionMessageHTML = [NSString stringWithFormat:@"<div class=\"page\"><p>%@ %@</p>", NSLocalizedString(@"The internet connection cannot reach your blog.", @""), NSLocalizedString(@"A simple preview is shown below.", @"")];
        previewPageHTML = [previewPageHTML stringByReplacingOccurrencesOfString:@"<div class=\"page\">" withString:noConnectionMessageHTML];
        [webView loadHTMLString:previewPageHTML baseURL:nil];
    } else if (link == nil ) {
        [webView loadHTMLString:[self buildSimplePreview] baseURL:nil];
    } else {

        // checks if this a scheduled post

        /*
         Forced the preview to use the login form. Otherwise the preview of pvt blog doesn't work.
         We can switch back to the normal call when we can access the blogOptions within the app.
         */

        //			NSDate *currentGMTDate = [DateUtils currentGMTDate];
        NSDate *postGMTDate = postDetailViewController.apost.date_created_gmt;
        NSDate *laterDate = postDetailViewController.apost.date_created_gmt;//[currentGMTDate laterDate:postGMTDate];

        if(isDraft || isPending || isPrivate || isPrivateBlog || ([laterDate isEqualToDate:postGMTDate])) {

            NSString *wpLoginURL = [postDetailViewController.apost.blog loginURL];
            NSURL *url = [NSURL URLWithString:wpLoginURL];
            NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:url];
            [req setHTTPMethod:@"POST"];
            [req addValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
            NSString *paramDataString = [NSString stringWithFormat:@"%@=%@&%@=%@&%@=%@",
                                         @"log", postDetailViewController.apost.blog.username,
                                         @"pwd", [[postDetailViewController.apost.blog fetchPassword] stringByUrlEncoding],
                                         @"redirect_to", link];

            NSData *paramData = [paramDataString dataUsingEncoding:NSUTF8StringEncoding];
            [req setHTTPBody: paramData];
            [req setValue:[NSString stringWithFormat:@"%d", [paramData length]] forHTTPHeaderField:@"Content-Length"];
            [req addValue:@"*/*" forHTTPHeaderField:@"Accept"];
            [webView loadRequest:req];
            WPFLog(@"Showing real preview (login) for %@", link);
        } else {
            [webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:link]]];
            WPFLog(@"Showing real preview for %@", link);
        }
    }
}

#pragma mark -
#pragma mark Webkit View Delegate Methods

- (void)refreshWebView {
	BOOL edited = [self.postDetailViewController hasChanges];
    loadingView.hidden = NO;

	if (edited) {
        BOOL autosave = [postDetailViewController autosaveRemoteWithSuccess:^{
            [self showRealPreview];
        } failure:^(NSError *error) {
            WPFLog(@"Error autosaving post for preview: %@", error);
            [webView loadHTMLString:[self buildSimplePreview] baseURL:nil];
        }];

        // Couldn't autosave: that means the post is already published, and any edits would be publicly saved
        if (!autosave) {
            [webView loadHTMLString:[self buildSimplePreview] baseURL:nil];
        }
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
    if (navigationType == UIWebViewNavigationTypeLinkClicked || navigationType == UIWebViewNavigationTypeFormSubmitted) {
        return NO;
    }
    return YES;
    //return isWebRefreshRequested || postDetailViewController.navigationItem.rightBarButtonItem != nil;
}

#pragma mark -

- (NSString *)stringReplacingNewlinesWithBR:(NSString *)surString {
    NSArray *comps = [surString componentsSeparatedByString:@"\n"];
    return [comps componentsJoinedByString:@"<br>"];
}


@end