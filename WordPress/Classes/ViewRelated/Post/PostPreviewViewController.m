#import "PostPreviewViewController.h"
#import "AbstractPost.h"
#import "PostCategory.h"
#import "WordPress-Swift.h"
#import "WPUserAgent.h"
#import "WPStyleGuide+Pages.h"
#import "WordPress-Swift.h"

@import Gridicons;
@import WordPressUI;



@interface PostPreviewViewController () <PostPreviewGeneratorDelegate, NoResultsViewControllerDelegate>

@property (nonatomic, strong) UIWebView *webView;
@property (nonatomic, strong) NSMutableData *receivedData;
@property (nonatomic, strong) AbstractPost *apost;
@property (nonatomic, strong) UIBarButtonItem *shareBarButtonItem;
@property (nonatomic, strong) UIBarButtonItem *doneBarButtonItem;
@property (nonatomic, strong) UIBarButtonItem *statusButtonItem;
@property (nonatomic, strong) PostPreviewGenerator *generator;
@property (nonatomic, strong) NoResultsViewController *noResultsViewController;
@property (nonatomic, strong) id reachabilityObserver;

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
        self.generator = [[PostPreviewGenerator alloc] initWithPost:aPost];
        self.generator.delegate = self;
    }
    return self;
}

- (instancetype)initWithPost:(AbstractPost *)aPost previewURL:(NSURL *)previewURL
{
    self = [super init];
    if (self) {
        self.apost = aPost;
        self.generator = [[PostPreviewGenerator alloc] initWithPost:aPost previewURL:previewURL];
        self.generator.delegate = self;
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
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    NSMutableArray *rightButtons = [NSMutableArray new];
    if (self.isModal) {
        [rightButtons addObject:[self doneBarButtonItem]];
    }
    if ([self.apost isKindOfClass:[Post class]]) {
        [rightButtons addObject:[self shareBarButtonItem]];
    }
    [self.navigationItem setRightBarButtonItems:rightButtons animated:YES];
    self.navigationItem.leftItemsSupplementBackButton = YES;
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self refreshWebView];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [self stopWaitingForConnectionRestored];
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

#pragma mark - Loading Animations

- (void)startLoadAnimation
{
    [self.navigationItem setLeftBarButtonItem:[self statusButtonItem] animated:YES];
    self.navigationItem.title = nil;
}

- (void)stopLoadAnimation
{
    self.navigationItem.leftBarButtonItem = self.navigationItem.backBarButtonItem;
    self.navigationItem.title  = NSLocalizedString(@"Preview", @"Post Editor / Preview screen title.");
}

#pragma mark - Reachability

- (void)reloadWhenConnectionRestored
{
    __weak __typeof(self) weakSelf = self;
    self.reachabilityObserver = [ReachabilityUtils observeOnceInternetAvailableWithAction:^{
        [weakSelf refreshWebView];
    }];
}

- (void)stopWaitingForConnectionRestored
{
    if (self.reachabilityObserver != nil) {
        [[NSNotificationCenter defaultCenter] removeObserver:self.reachabilityObserver];
        self.reachabilityObserver = nil;
    }
}

#pragma mark -
#pragma mark Webkit View Delegate Methods

- (void)refreshWebView
{
    [self.generator generate];
}

- (void)webViewDidFinishLoad:(UIWebView *)awebView
{
    DDLogMethod();
    [self stopLoadAnimation];
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error
{
    DDLogMethodParam(error);

    // Watch for NSURLErrorCancelled (aka NSURLErrorDomain error -999). This error is returned
    // when an asynchronous load is canceled. For example, a link is tapped (or some other
    // action that causes a new page to load) before the current page has completed loading.
    // It should be safe to ignore.
    if([error.domain isEqualToString:NSURLErrorDomain] && error.code == NSURLErrorCancelled) {
        return;
    }

    // In iOS 11, it seems UIWebView is based on WebKit, and it's returning a different error when
    // we redirect and cancel a request from shouldStartLoadWithRequest:
    //
    //   Error Domain=WebKitErrorDomain Code=102 "Frame load interrupted"
    //
    // I haven't found a relevant WebKit constant for error 102
    if ([error.domain isEqualToString:@"WebKitErrorDomain"] && error.code == 102) {
        return;
    }

    [self stopLoadAnimation];
    
    [self.generator previewRequestFailedWithReason:[NSString stringWithFormat:@"Generic web view error Error. Error code: %d, Error domain: %@", error.code, error.domain]];
}

- (BOOL)webView:(UIWebView *)awebView
        shouldStartLoadWithRequest:(NSURLRequest *)request
        navigationType:(UIWebViewNavigationType)navigationType
{
    NSURLRequest *redirectRequest = [self.generator interceptRedirectWithRequest:request];
    if (redirectRequest != NULL) {
        DDLogInfo(@"Found redirect to %@", redirectRequest);
        [self.webView loadRequest:redirectRequest];
        return NO;
    }

    if ([[[request URL] query] isEqualToString:@"action=postpass"]) {
        // Password-protected post, user entered password
        return YES;
    }

    if ([[[request URL] absoluteString] isEqualToString:self.apost.permaLink]) {
        // Always allow loading the preview
        return YES;
    }

    if (navigationType == UIWebViewNavigationTypeLinkClicked) {
        // Open the link
        UIApplication *application = [UIApplication sharedApplication];
        [application openURL:[request URL] options:@{} completionHandler:nil];
        return NO;
    }
    
    if (navigationType == UIWebViewNavigationTypeFormSubmitted) {
        return NO;
    }
    
    return YES;
}

#pragma mark - PostPreviewGeneratorDelegate

- (void)preview:(PostPreviewGenerator *)generator loadHTML:(NSString *)html {
    [self.webView loadHTMLString:html baseURL:nil];
    [self.noResultsViewController removeFromView];
}

- (void)preview:(PostPreviewGenerator *)generator attemptRequest:(NSURLRequest *)request {
    [self startLoadAnimation];
    [self.webView loadRequest:request];
    [self.noResultsViewController removeFromView];
}

- (void)previewFailed:(PostPreviewGenerator *)generator message:(NSString *)message {
    [self showNoResultsWithTitle:message];
    [self reloadWhenConnectionRestored];
}

#pragma mark - No Results

- (void)actionButtonPressed {
    [self stopWaitingForConnectionRestored];
    [self.noResultsViewController removeFromView];
    [self refreshWebView];
}

- (void)showNoResultsWithTitle:(NSString *)title {
    self.noResultsViewController = [NoResultsViewController controllerWithTitle:title
                                                                    buttonTitle:NSLocalizedString(@"Retry", @"Button to retry a preview that failed to load")
                                                                       subtitle:nil
                                                             attributedSubtitle:nil
                                                attributedSubtitleConfiguration:nil
                                                                          image:nil
                                                                  subtitleImage:nil
                                                                  accessoryView:nil];
    self.noResultsViewController.delegate = self;

    [self.view layoutIfNeeded];
    [self addChildViewController:self.noResultsViewController];

    [self.view addSubview:self.noResultsViewController.view];
    self.noResultsViewController.view.frame = self.view.bounds;
    [self.noResultsViewController didMoveToParentViewController:self];
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

- (UIBarButtonItem *)statusButtonItem
{
    if (!_statusButtonItem) {
        LoadingStatusView *statusView = [[LoadingStatusView alloc] initWithTitle: NSLocalizedString(@"Loading", @"Label for button to present loading preview status")];
        _statusButtonItem = [[UIBarButtonItem alloc] initWithCustomView:statusView];
        _statusButtonItem.accessibilityIdentifier = @"Preview Status";
    }
    
    return _statusButtonItem;
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
