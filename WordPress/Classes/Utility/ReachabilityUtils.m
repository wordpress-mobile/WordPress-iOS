#import "ReachabilityUtils.h"
#import "WordPressAppDelegate.h"
#import "WordPress-Swift.h"

@interface ReachabilityAlert : NSObject
@property (nonatomic, copy) void (^retryBlock)();

- (instancetype)initWithRetryBlock:(void (^)())retryBlock;

- (void)show;
@end

static ReachabilityAlert *__currentReachabilityAlert = nil;

@implementation ReachabilityAlert

- (instancetype)initWithRetryBlock:(void (^)())retryBlock
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
    NSString *message = NSLocalizedString(@"The Internet connection appears to be offline.", @"");
    
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

+ (void)showAlertNoInternetConnectionWithRetryBlock:(void (^)())retryBlock
{
    ReachabilityAlert *alert = [[ReachabilityAlert alloc] initWithRetryBlock:retryBlock];
    [alert show];
}

@end
