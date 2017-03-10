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
@import SVProgressHUD;
@interface PostPreviewViewController () <PostPreviewGeneratorDelegate>

@property (nonatomic, strong) UIWebView *webView;
@property (nonatomic, strong) NSMutableData *receivedData;
@property (nonatomic, strong) AbstractPost *apost;
@property (nonatomic, strong) UIBarButtonItem *shareBarButtonItem;
@property (nonatomic, strong) UIBarButtonItem *doneBarButtonItem;
@property (nonatomic, strong) PostPreviewGenerator *generator;

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

#pragma mark - Loading

- (void)startLoading
{
    [SVProgressHUD show];
}

- (void)stopLoading
{
    [SVProgressHUD dismiss];
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
    [self stopLoading];
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

    [self stopLoading];
    [self.generator previewRequestFailedWithError:error];
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

#pragma mark - PostPreviewGeneratorDelegate

- (void)preview:(PostPreviewGenerator *)generator loadHTML:(NSString *)html {
    [self.webView loadHTMLString:html baseURL:nil];
}

- (void)preview:(PostPreviewGenerator *)generator attemptRequest:(NSURLRequest *)request {
    [self startLoading];
    [self.webView loadRequest:request];
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
