#import "ReachabilityUtils.h"
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
    if (__currentReachabilityAlert) {
        return;
    }
    
    NSString *title = NSLocalizedString(@"No Connection", @"");
    NSString *message = [ReachabilityUtils noConnectionMessage];
    
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:title
                                                                             message:message
                                                                      preferredStyle:UIAlertControllerStyleAlert];
    
    [alertController addCancelActionWithTitle:NSLocalizedString(@"OK", @"") handler:^(UIAlertAction *action) {
        __currentReachabilityAlert = nil;
    }];
    
    if (self.retryBlock) {
        [alertController addDefaultActionWithTitle:NSLocalizedString(@"Retry?", @"") handler:^(UIAlertAction *action) {
            self.retryBlock();
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

+ (void)showAlertNoInternetConnectionWithRetryBlock:(void (^)(void))retryBlock
{
    ReachabilityAlert *alert = [[ReachabilityAlert alloc] initWithRetryBlock:retryBlock];
    [alert show];
}

+ (NSString *)noConnectionMessage
{
    return NSLocalizedString(@"The internet connection appears to be offline.",
            @"Message of error prompt shown when a user tries to perform an action without an internet connection.");
}

+ (BOOL)alertIsShowing
{
    return __currentReachabilityAlert != nil;
}
@end
