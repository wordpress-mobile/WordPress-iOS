#import "PostPreviewViewController.h"
#import "AbstractPost.h"
#import "WordPressAppDelegate.h"
#import "WPURLRequest.h"
#import "PostCategory.h"
#import "WordPress-Swift.h"
#import "WPUserAgent.h"
#import "WPStyleGuide+Posts.h"
#import "WordPress-Swift.h"

@import Gridicons;
@interface PostPreviewViewController ()

@property (nonatomic, strong) UIWebView *webView;
@property (nonatomic, strong) UIView *loadingView;
@property (nonatomic, strong) NSMutableData *receivedData;
@property (nonatomic, strong) AbstractPost *apost;
@property (nonatomic, strong) UIBarButtonItem *shareBarButtonItem;
@property (nonatomic, strong) UIBarButtonItem *doneBarButtonItem;

@end

@implementation PostPreviewViewController

#pragma mark -
#pragma mark Lifecycle Methods

- (void)dealloc
{
    [self.webView stopLoading];
    self.webView.delegate = nil;
}

- (instancetype)initWithPost:(AbstractPost *)aPost
{
    self = [super init];
    if (self) {
        self.apost = aPost;
        self.navigationItem.title = NSLocalizedString(@"Preview", @"Post Editor / Preview screen title.");
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
    [self refreshWebView];
    NSMutableArray *rightButtons = [NSMutableArray new];
    if (self.isModal) {
        [rightButtons addObject:[self doneBarButtonItem]];
    }
    if ([self.apost isKindOfClass:[Post class]]) {
        [rightButtons addObject:[self shareBarButtonItem]];
    }
    [self.navigationItem setRightBarButtonItems:rightButtons animated:YES];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
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

- (void)showSimplePreviewWithMessage:(NSString *)message
{
    DDLogMethod();
    FakePreviewBuilder *builder = [[FakePreviewBuilder alloc] initWithApost:self.apost message:message];
    NSString *previewPageHTML = [builder build];
    previewPageHTML = [builder build];
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
            NSString *username = self.apost.blog.usernameForSite;
            NSString *token, *password;
            if ([self.apost.blog supports:BlogFeatureOAuth2Login]) {
                password = nil;
                token = self.apost.blog.authToken;
            } else {
                password = self.apost.blog.password;
                token = nil;
            }

            if (username.length > 0 && (password.length > 0 || token.length > 0)) {
                NSURLRequest *request = [WPURLRequest requestForAuthenticationWithURL:loginURL
                                                                          redirectURL:redirectURL
                                                                             username:username
                                                                             password:password
                                                                          bearerToken:token
                                                                            userAgent:nil];
                [self.webView loadRequest:request];
                DDLogInfo(@"Showing real preview (login) for %@", link);
            } else {
                [self showSimplePreview];
            }
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

#pragma mark - Custom UI elements

- (UIBarButtonItem *)shareBarButtonItem
{
    if (!_shareBarButtonItem) {
        UIImage *image = [Gridicon iconOfType:GridiconTypeShareIOS];
        _shareBarButtonItem = [[UIBarButtonItem alloc] initWithImage:image
                                                               style:UIBarButtonItemStylePlain
                                                              target:self
                                                              action:@selector(sharePost)];
        NSString *title = NSLocalizedString(@"Share", @"Title of the share button in the Post Editor.");
        _shareBarButtonItem.accessibilityLabel = title;
        _shareBarButtonItem.accessibilityIdentifier = @"Share";
    }
    
    return _shareBarButtonItem;
}

- (UIBarButtonItem *)doneBarButtonItem
{
    if (!_doneBarButtonItem) {
        _doneBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Done", @"Label for button to dismiss post preview") style:UIBarButtonItemStyleDone target:self action:@selector(dismissPreview)];
        _doneBarButtonItem.accessibilityIdentifier = @"Done";
    }

    return _doneBarButtonItem;
}

- (void)sharePost
{
    if ([self.apost isKindOfClass:[Post class]]) {
        Post *post = (Post *)self.apost;
        
        PostSharingController *sharingController = [[PostSharingController alloc] init];
        
        [sharingController sharePost:post fromBarButtonItem:[self shareBarButtonItem] inViewController:self];
    }
}

- (void)dismissPreview
{
    if (self.onClose) {
        self.onClose();
        self.onClose = nil;
    } else{
        [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
    }
}

@end
