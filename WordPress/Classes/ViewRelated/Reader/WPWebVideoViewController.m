#import "WPWebVideoViewController.h"
#import "WordPressAppDelegate.h"

@interface WPWebVideoViewController ()<UIWebViewDelegate>

@property (nonatomic, strong) UIWebView *webView;
@property (nonatomic, strong) UIActivityIndicatorView *activityView;
@property (nonatomic, strong) NSURL *url;
@property (nonatomic, strong) NSString *html;
@property (nonatomic, strong) UILabel *titleLabel;

- (void)handleCloseTapped:(id)sender;

@end

@implementation WPWebVideoViewController

#pragma mark - LifeCycle Methods

- (id)initWithURL:(NSURL *)url
{
    self = [self init];
    if (self) {
        self.url = url;
    }

    return self;
}

- (id)initWithHTML:(NSString *)html
{
    self = [self init];
    if (self) {
        self.html = html;
    }

    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                                                                          target:self
                                                                                          action:@selector(handleCloseTapped:)];

    CGFloat y = UIInterfaceOrientationIsPortrait(self.interfaceOrientation) ? 6.0f : 0.0f;
    UIView *titleView = [[UIView alloc] initWithFrame:CGRectMake(0.0f, y, 200.0f, 32.0f)];
    titleView.backgroundColor = [UIColor clearColor];
    titleView.autoresizingMask = UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleTopMargin;

    self.titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0.0f, 0.0f, 200.0f, 18.0f)];
    _titleLabel.font = [WPStyleGuide regularTextFontBold];
    _titleLabel.textColor = [UIColor whiteColor];
    _titleLabel.textAlignment = NSTextAlignmentCenter;
    _titleLabel.text = self.title;
    _titleLabel.backgroundColor = [UIColor clearColor];
    _titleLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    [titleView addSubview:_titleLabel];

    UILabel *urlLabel = [[UILabel alloc] initWithFrame:CGRectMake(0.0f, 18.0f, 200.0f, 14.0f)];
    urlLabel.font = [WPStyleGuide subtitleFont];
    urlLabel.textColor = [UIColor whiteColor];
    urlLabel.textAlignment = NSTextAlignmentCenter;
    urlLabel.text = [self.url absoluteString];
    urlLabel.backgroundColor = [UIColor clearColor];
    urlLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    [titleView addSubview:urlLabel];

    self.navigationItem.titleView = titleView;

    self.webView = [[UIWebView alloc] initWithFrame:self.view.bounds];
    _webView.delegate = self;
    _webView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    _webView.backgroundColor = [UIColor blackColor];
    [_webView stringByEvaluatingJavaScriptFromString:@"document.body.style.background = '#000000';"];
    [self.view addSubview:_webView];

    self.activityView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
    _activityView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleBottomMargin;
    _activityView.hidesWhenStopped = YES;
    CGRect frame = _activityView.frame;
    frame.origin.x = (self.view.frame.size.width / 2.0f) - (frame.size.width / 2.0f);
    frame.origin.y = (self.view.frame.size.height / 2.0f) - (frame.size.height / 2.0f);
    _activityView.frame = frame;
    [self.view addSubview:_activityView];

    if (_url) {
        [_webView loadRequest:[NSURLRequest requestWithURL:_url]];

    } else {
        [_webView loadHTMLString:_html baseURL:nil];
    }
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return [super shouldAutorotateToInterfaceOrientation:interfaceOrientation];
}

#pragma mark - Instance Methods

- (void)setTitle:(NSString *)title
{
    [super setTitle:title];
    _titleLabel.text = title;
}

- (void)handleCloseTapped:(id)sender
{
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - UIWebView Delegate Methods

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error
{
    DDLogMethodParam(error);
    // TODO: Show a nice content can't be displayed message if there is a problem loading or the content is bogus.
}

- (void)webViewDidStartLoad:(UIWebView *)webView
{
    [_activityView startAnimating];
}

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    [_activityView stopAnimating];
}

@end
