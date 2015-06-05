#import "AboutViewController.h"
#import "ReachabilityUtils.h"
#import "WPWebViewController.h"
#import "NSBundle+VersionNumberHelper.h"
#import "Constants.h"


@interface AboutViewController()

@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (nonatomic, weak) IBOutlet UILabel *titleLabel;
@property (nonatomic, weak) IBOutlet UILabel *versionLabel;
@property (nonatomic, weak) IBOutlet UILabel *publisherLabel;
@property (nonatomic, weak) IBOutlet UIButton *viewWebsiteButton;
@property (nonatomic, weak) IBOutlet UIButton *tosButton;
@property (nonatomic, weak) IBOutlet UIButton *privacyPolicyButton;

@end

@implementation AboutViewController

CGFloat const AboutViewLandscapeButtonsY = -20.0f;
CGFloat const AboutViewPortraitButtonsY = 90.0f;

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad
{
    DDLogInfo(@"%@ %@", self, NSStringFromSelector(_cmd));
    [super viewDidLoad];

    self.navigationItem.title = NSLocalizedString(@"About", @"About this app (information page title)");

    self.view.backgroundColor = [WPStyleGuide itsEverywhereGrey];

    self.titleLabel.text = NSLocalizedString(@"WordPress for iOS", nil);
    self.titleLabel.font = [WPStyleGuide largePostTitleFont];
    self.titleLabel.textColor = [WPStyleGuide whisperGrey];

    self.versionLabel.text = [[NSBundle mainBundle] detailedVersionNumber];
    self.versionLabel.font = [WPStyleGuide postTitleFont];
    self.versionLabel.textColor = [WPStyleGuide whisperGrey];

    self.publisherLabel.font = [WPStyleGuide regularTextFont];
    self.publisherLabel.textColor = [WPStyleGuide whisperGrey];

    self.viewWebsiteButton.titleLabel.font = [WPStyleGuide subtitleFont];
    self.viewWebsiteButton.titleLabel.textColor = [WPStyleGuide whisperGrey];

    [self.tosButton setBackgroundImage:nil forState:UIControlStateNormal];
    [self.tosButton setBackgroundImage:nil forState:UIControlStateHighlighted];
    [self.tosButton setTitleColor:[WPStyleGuide buttonActionColor] forState:UIControlStateNormal];
    self.tosButton.titleLabel.font = [WPStyleGuide postTitleFont];
    [self.tosButton setTitle:NSLocalizedString(@"Terms of Service", nil) forState:UIControlStateNormal];

    [self.privacyPolicyButton setBackgroundImage:nil forState:UIControlStateNormal];
    [self.privacyPolicyButton setBackgroundImage:nil forState:UIControlStateHighlighted];
    [self.privacyPolicyButton setTitleColor:[WPStyleGuide buttonActionColor] forState:UIControlStateNormal];

    [self.privacyPolicyButton setTitle:NSLocalizedString(@"Privacy Policy", nil) forState:UIControlStateNormal];
    self.privacyPolicyButton.titleLabel.font = [WPStyleGuide postTitleFont];

    self.scrollView.contentSize = CGSizeMake(CGRectGetWidth(self.scrollView.frame), CGRectGetMaxY(self.viewWebsiteButton.frame));

    if ([self.navigationController.viewControllers count] == 1) {
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Close", @"") style:[WPStyleGuide barButtonStyleForBordered] target:self action:@selector(dismiss)];
    }
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return [super shouldAutorotateToInterfaceOrientation:interfaceOrientation];
}

#pragma mark - Custom methods

- (void)dismiss
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)viewTermsOfService:(id)sender
{
    [self openURLWithString:WPAutomatticTermsOfServiceURL];
}

- (IBAction)viewPrivacyPolicy:(id)sender
{
    [self openURLWithString:WPAutomatticPrivacyURL];
}

- (IBAction)viewWebsite:(id)sender
{
    [self openURLWithString:WPAutomatticMainURL];
}

- (void)openURLWithString:(NSString *)path
{
    if (![ReachabilityUtils isInternetReachable]) {
        [ReachabilityUtils showAlertNoInternetConnection];
        return;
    }
    
    NSURL *targetURL = [NSURL URLWithString:path];
    WPWebViewController *webViewController = [WPWebViewController webViewControllerWithURL:targetURL];
    
    if (self.presentingViewController) {
        [self.navigationController pushViewController:webViewController animated:YES];
        return;
    }
    
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:webViewController];
    [self presentViewController:navController animated:YES completion:nil];
}

@end
