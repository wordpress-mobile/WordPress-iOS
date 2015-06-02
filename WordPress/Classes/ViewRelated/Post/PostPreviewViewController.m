#import "PostPreviewViewController.h"
#import "WordPressAppDelegate.h"
#import "WPURLRequest.h"
#import "Post.h"
#import "PostCategory.h"
#import "WPUserAgent.h"

@interface PostPreviewViewController ()

@property (nonatomic, strong) UIWebView *webView;
@property (nonatomic, strong) UIView *loadingView;
@property (nonatomic, strong) NSMutableData *receivedData;
@property (nonatomic, strong) AbstractPost *apost;
@property (nonatomic, assign) BOOL *shouldHideStatusBar;

@end

@implementation PostPreviewViewController

#pragma mark -
#pragma mark Lifecycle Methods

- (void)dealloc
{
    [[WordPressAppDelegate sharedInstance].userAgent useWordPressUserAgent];
    [self.webView stopLoading];
    self.webView.delegate = nil;
}

- (instancetype)initWithPost:(AbstractPost *)aPost shouldHideStatusBar:(BOOL)shouldHideStatusBar
{
    self = [super init];
    if (self) {
        self.apost = aPost;
        self.navigationItem.title = NSLocalizedString(@"Preview", @"Post Editor / Preview screen title.");
        self.shouldHideStatusBar = shouldHideStatusBar;
    }
    return self;
}

- (void)didReceiveMemoryWarning
{
    DDLogMethod();
    [super didReceiveMemoryWarning];
}

- (void)viewDidLoad
{
    DDLogMethod();
    
    [super viewDidLoad];
    [self setupWebView];
    [self setupLoadingView];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [[WordPressAppDelegate sharedInstance].userAgent useDefaultUserAgent];
    [self refreshWebView];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [[WordPressAppDelegate sharedInstance].userAgent useWordPressUserAgent];
    [self.webView stopLoading];
}

#pragma mark -
#pragma mark Instance Methods

- (void)setupWebView
{
    if (!self.webView) {
        self.webView = [[UIWebView alloc] initWithFrame:self.view.bounds];
        self.webView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        self.webView.delegate = self;
    }
    [self.view addSubview:self.webView];
}

- (void)setupLoadingView
{
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

- (Post *)post
{
    if ([self.apost isKindOfClass:[Post class]]) {
        return (Post *)self.apost;
    }

    return nil;
}

- (NSString *)buildSimplePreview
{
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
            PostCategory *category = [categories objectAtIndex:i];
            catStr = [catStr stringByAppendingString:category.categoryName];
            if (i < count-1) {
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

- (void)showSimplePreviewWithMessage:(NSString *)message
{
    DDLogMethod();
    NSString *previewPageHTML = [self buildSimplePreview];
    if (message) {
        previewPageHTML = [previewPageHTML stringByReplacingOccurrencesOfString:@"<div class=\"page\">" withString:[NSString stringWithFormat:@"<div class=\"page\"><p>%@</p>", message]];
    }
    [self.webView loadHTMLString:previewPageHTML baseURL:nil];
}

- (void)showSimplePreview
{
    [self showSimplePreviewWithMessage:nil];
}

- (void)showRealPreview
{
    BOOL needsLogin = NO;
    NSString *status = self.apost.status;

    if ([status isEqualToString:PostStatusDraft]) {
        needsLogin = YES;
    } else if ([status isEqualToString:PostStatusPrivate]) {
        needsLogin = YES;
    } else if ([status isEqualToString:PostStatusPending]) {
        needsLogin = YES;
    } else if ([self.apost.blog isPrivate]) {
        needsLogin = YES; // Private blog
    } else if ([self.apost isScheduled]) {
        needsLogin = YES; // Scheduled post
    }

    NSString *link = self.apost.permaLink;

    WordPressAppDelegate *appDelegate = [WordPressAppDelegate sharedInstance];

    if (appDelegate.connectionAvailable == NO) {
        [self showSimplePreviewWithMessage:[NSString stringWithFormat:@"<div class=\"page\"><p>%@ %@</p>", NSLocalizedString(@"The internet connection appears to be offline.", @""), NSLocalizedString(@"A simple preview is shown below.", @"")]];
    } else if (link == nil) {
        [self showSimplePreview];
    } else {
        if (needsLogin) {
            NSURL *loginURL = [NSURL URLWithString:self.apost.blog.loginUrl];
            NSURL *redirectURL = [NSURL URLWithString:link];
            NSString *token;
            if ([self.apost.blog supports:BlogFeatureOAuth2Login]) {
                token = self.apost.blog.authToken;
            }

            NSURLRequest *request = [WPURLRequest requestForAuthenticationWithURL:loginURL
                                                                      redirectURL:redirectURL
                                                                         username:self.apost.blog.username
                                                                         password:self.apost.blog.password
                                                                      bearerToken:token
                                                                        userAgent:nil];
            [self.webView loadRequest:request];
            DDLogInfo(@"Showing real preview (login) for %@", link);
        } else {
            [self.webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:link]]];
            DDLogInfo(@"Showing real preview for %@", link);
        }
    }
}

#pragma mark -
#pragma mark Webkit View Delegate Methods

- (void)refreshWebView
{
    BOOL edited = [self.apost hasLocalChanges];
    self.loadingView.hidden = NO;

    if (edited) {
        [self showSimplePreview];
    } else {
        [self showRealPreview];
    }
}

- (void)webViewDidStartLoad:(UIWebView *)webView
{
    DDLogMethod();
    self.loadingView.hidden = NO;
}

- (void)webViewDidFinishLoad:(UIWebView *)awebView
{
    DDLogMethod();
    self.loadingView.hidden = YES;
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error
{
    DDLogMethodParam(error);

    // Watch for NSURLErrorCancelled (aka NSURLErrorDomain error -999). This error is returned
    // when an asynchronous load is canceled. For example, a link is tapped (or some other
    // action that causes a new page to load) before the current page has completed loading.
    // It should be safe to ignore.
    if([error code] == NSURLErrorCancelled) {
        return;
    }

    self.loadingView.hidden = YES;
    NSString *errorMessage = [NSString stringWithFormat:@"<div class=\"page\"><p>%@ %@</p>",
                              NSLocalizedString(@"There has been an error while trying to reach your site.", nil),
                              NSLocalizedString(@"A simple preview is shown below.", @"")];

    [self showSimplePreviewWithMessage:errorMessage];
}

- (BOOL)webView:(UIWebView *)awebView
        shouldStartLoadWithRequest:(NSURLRequest *)request
        navigationType:(UIWebViewNavigationType)navigationType
{
    if ([[[request URL] query] isEqualToString:@"action=postpass"]) {
        // Password-protected post, user entered password
        return YES;
    }

    if ([[[request URL] absoluteString] isEqualToString:self.apost.permaLink]) {
        // Always allow loading the preview
        return YES;
    }

    if (navigationType == UIWebViewNavigationTypeLinkClicked || navigationType == UIWebViewNavigationTypeFormSubmitted) {
        return NO;
    }
    return YES;
}

#pragma mark -

- (NSString *)stringReplacingNewlinesWithBR:(NSString *)surString
{
    NSArray *comps = [surString componentsSeparatedByString:@"\n"];
    return [comps componentsJoinedByString:@"<br>"];
}

#pragma mark - Status bar management

- (BOOL)prefersStatusBarHidden
{
    // Do not hide status bar on iPad
    return (self.shouldHideStatusBar && !IS_IPAD);
}

@end