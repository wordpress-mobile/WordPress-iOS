#import <Helpshift/Helpshift.h>
#import <wpxmlrpc/WPXMLRPC.h>

#import "WPNUXErrorViewController.h"
#import "WPWebViewController.h"
#import "SupportViewController.h"
#import "WPWalkthroughOverlayView.h"

@interface WPNUXErrorViewController ()
@property (nonatomic, strong) WPWalkthroughOverlayView *overlayView;
@property (nonatomic, strong) NSError *error;
@end

@implementation WPNUXErrorViewController

- (instancetype)initWithRemoteError:(NSError *)error
{
    self = [super init];
    if (self) {
        _error = error;
        self.modalPresentationStyle = UIModalPresentationOverFullScreen;
        self.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
    }
    return self;
}

- (void)loadView
{
    UIView *view = [self newWrapperView];
    view.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;

    UIView *contentView = [[UIView alloc] initWithFrame:view.bounds];
    contentView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    [view addSubview:contentView];

    self.overlayView = [[WPWalkthroughOverlayView alloc] initWithFrame:contentView.bounds];
    self.overlayView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    [contentView addSubview:self.overlayView];

    [self configureOverlayView];

    self.view = view;
}

- (UIView *)newWrapperView
{
    if (NSClassFromString(@"UIVisualEffectView")) {
        UIBlurEffect *blurEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleDark];
        UIVisualEffectView *visualEffect = [[UIVisualEffectView alloc] initWithEffect:blurEffect];
        return visualEffect;
    } else {
        UIView *view = [[UIView alloc] initWithFrame:CGRectZero];
        view.backgroundColor = [UIColor colorWithRed:17.0/255.0 green:17.0/255.0 blue:17.0/255.0 alpha:0.95];
        return view;
    }
}

- (void)configureOverlayView
{
    self.overlayView.overlayMode = WPWalkthroughGrayOverlayViewOverlayModeTwoButtonMode;
    self.overlayView.overlayTitle = NSLocalizedString(@"Sorry, we can't log you in.", nil);
    self.overlayView.secondaryButtonText = NSLocalizedString(@"Need Help?", nil);
    self.overlayView.primaryButtonText = NSLocalizedString(@"OK", nil);

    __weak __typeof(self)weakSelf = self;
    self.overlayView.dismissCompletionBlock = ^(WPWalkthroughOverlayView *overlayView) {
        [weakSelf dismiss];
    };
    self.overlayView.primaryButtonCompletionBlock = ^(WPWalkthroughOverlayView *overlayView) {
        [weakSelf dismiss];
    };

    if (self.liveChatEnabled) {
        self.overlayView.secondaryButtonText = NSLocalizedString(@"Contact Us", @"The text on the button at the bottom of the error message when a user has repeated trouble logging in");
        self.overlayView.secondaryButtonCompletionBlock = ^(WPWalkthroughOverlayView *overlayView){
            [weakSelf dismissWithLiveChat];
        };
    } else {
        self.overlayView.secondaryButtonCompletionBlock = ^(WPWalkthroughOverlayView *overlayView){
            [weakSelf dismissWithHelp];
        };
    }

    [self configureOverlayViewWithError];
}

- (void)configureOverlayViewWithError
{
    self.overlayView.overlayDescription = [self.error localizedDescription];

    if ([[self.error domain] isEqualToString:WPXMLRPCFaultErrorDomain]) {
        [self configureOverlayViewWithXMLRPCError];
    } else if ([self.error.localizedDescription rangeOfString:@"application-specific"].location != NSNotFound) {
        [self configureHelpActionWithGenerateApplicationSpecificPasswordErrorMessage];
    }
}

- (void)configureOverlayViewWithXMLRPCError
{
    NSString *message = [self.error localizedDescription];
    if ([self.error code] == 403) {
        message = NSLocalizedString(@"Please try entering your login details again.", nil);
    }

    if ([[message trim] length] == 0) {
        message = NSLocalizedString(@"Sign in failed. Please try again.", nil);
    }
    self.overlayView.overlayDescription = message;

    if ([self.error code] == 405) {
        [self configureHelpActionWithDisabledXMLRPCError];
    } else {
        if ([self.error code] == NSURLErrorBadURL) {
            [self configureHelpActionWithBadURL];
        }
    }
}

- (void)configureHelpActionWithDisabledXMLRPCError
{
    [self configureHelpActionWithFAQItemID:@11];
}

- (void)configureHelpActionWithGenerateApplicationSpecificPasswordErrorMessage
{
    NSURL *url = [NSURL URLWithString:@"http://en.support.wordpress.com/security/two-step-authentication/#application-specific-passwords"];
    [self configureHelpActionWithURL:url];
}

- (void)configureHelpActionWithBadURL
{
    [self configureHelpActionWithFAQItemID:@3];
}

- (void)configureHelpActionWithFAQItemID:(NSNumber *)faqItem
{
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"https://apps.wordpress.org/support/#faq-ios-%@", faqItem]];
    [self configureHelpActionWithURL:url];
}

- (void)configureHelpActionWithURL:(NSURL *)url
{
    __weak __typeof(self)weakSelf = self;
    self.overlayView.secondaryButtonCompletionBlock = ^(WPWalkthroughOverlayView *overlayView) {
        WPWebViewController *webViewController = [[WPWebViewController alloc] init];
        [webViewController setUrl:url];
        [weakSelf dismissWithNextController:webViewController];
    };
}

- (void)dismiss
{
    [self dismissWithNextController:nil];
}

- (void)dismissWithNextController:(UIViewController *)controller
{
    if (self.dismissCompletionBlock) {
        self.dismissCompletionBlock(controller);
    }
}

- (void)dismissWithHelp
{
    [self dismissWithNextController:[SupportViewController new]];
}

- (void)dismissWithLiveChat
{
    if (self.contactCompletionBlock) {
        self.contactCompletionBlock();
    }
}

@end
