#import "ReachabilityUtils.h"
#import "WordPressAppDelegate.h"
#import "WordPress-Swift.h"

@import WordPressUI;


@interface ReachabilityAlert : NSObject
@property (nonatomic, copy) void (^retryBlock)(void);

- (instancetype)initWithRetryBlock:(void (^)(void))retryBlock;

- (void)show;
@end

static ReachabilityAlert *__currentReachabilityAlert = nil;

@implementation ReachabilityAlert

- (instancetype)initWithRetryBlock:(void (^)(void))retryBlock
{
    self = [super init];
    if (self) {
        self.retryBlock = retryBlock;
    }
    return self;
}

- (void)show
{
    [self showWithTitle:NSLocalizedString(@"No Connection", @"") andMessage:[ReachabilityUtils noConnectionMessage]];
}

- (void)showWithMessage:(NSString *)message
{
    [self showWithTitle:NSLocalizedString(@"Error", @"Generic error alert title") andMessage:message];
}

- (void)showWithTitle:(NSString *)title andMessage:(NSString *)message
{
    if (__currentReachabilityAlert) {
        return;
    }
    
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:title
                                                                             message:message
                                                                      preferredStyle:UIAlertControllerStyleAlert];
    
    [alertController addCancelActionWithTitle:NSLocalizedString(@"OK", @"") handler:^(UIAlertAction *action) {
        __currentReachabilityAlert = nil;
    }];
    
    
    if (self.retryBlock) {
        [alertController addDefaultActionWithTitle:NSLocalizedString(@"Retry?", @"") handler:^(UIAlertAction *action) {
            self.retryBlock();
        }];
    } else if (ReachabilityUtils.isInternetReachable) {
        // Add the 'Need help' button only if internet is accessible (i.e. if the user can actually get help).
        NSString *supportText = NSLocalizedString(@"Need Help?", @"'Need help?' button label, links off to the WP for iOS FAQ.");
        [alertController addDefaultActionWithTitle:supportText handler:^(UIAlertAction *action) {
            SupportTableViewController *supportVC = [SupportTableViewController new];
            [supportVC showFromTabBar];
            __currentReachabilityAlert = nil;
        }];
    }
    
    // Note: This viewController might not be visible anymore
    [alertController presentFromRootViewController];

    __currentReachabilityAlert = self;
}

@end

@implementation ReachabilityUtils

+ (BOOL)isInternetReachable
{
    WordPressAppDelegate *appDelegate = (WordPressAppDelegate *) [[UIApplication sharedApplication] delegate];
    return appDelegate.connectionAvailable;
}

+ (void)showAlertNoInternetConnection
{
    ReachabilityAlert *alert = [[ReachabilityAlert alloc] initWithRetryBlock:nil];
    [alert show];
}

+ (void)showConnectionErrorAlertWithMessage:(NSString *)message
{
    ReachabilityAlert *alert = [[ReachabilityAlert alloc] initWithRetryBlock:nil];
    [alert showWithMessage:message];
}

+ (void)showAlertNoInternetConnectionWithRetryBlock:(void (^)(void))retryBlock
{
    ReachabilityAlert *alert = [[ReachabilityAlert alloc] initWithRetryBlock:retryBlock];
    [alert show];
}

+ (NSString *)noConnectionMessage
{
    return NSLocalizedString(@"The Internet connection appears to be offline.", @"");
}

+ (BOOL)alertIsShowing
{
    return __currentReachabilityAlert != nil;
}
@end
