#import "ReachabilityUtils.h"
#import "WordPressAppDelegate.h"

@interface ReachabilityAlert : NSObject <UIAlertViewDelegate>
@property(nonatomic, copy) void (^retryBlock)();

- (id)initWithRetryBlock:(void (^)())retryBlock;

- (void)show;
@end

static ReachabilityAlert *__currentReachabilityAlert = nil;

@implementation ReachabilityAlert

- (id)initWithRetryBlock:(void (^)())retryBlock
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
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"No Connection", @"")
                                                        message:NSLocalizedString(@"The Internet connection appears to be offline.", @"")
                                                       delegate:self
                                              cancelButtonTitle:NSLocalizedString(@"OK", @"")
                                              otherButtonTitles:nil];
    if (self.retryBlock) {
        [alertView addButtonWithTitle:NSLocalizedString(@"Retry?", @"")];
    }
    [alertView show];
    __currentReachabilityAlert = self;
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    __currentReachabilityAlert = nil;
    if (buttonIndex == 1 && self.retryBlock) {
        self.retryBlock();
    }
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
