#import <UIKit/UIKit.h>

@interface LoginViewController : UIViewController

@property (nonatomic, assign) BOOL onlyDotComAllowed;
@property (nonatomic, assign) BOOL prefersSelfHosted;
@property (nonatomic, assign) BOOL shouldReauthenticateDefaultAccount;
@property (nonatomic, assign) BOOL showEditorAfterAddingSites;
@property (nonatomic, assign) BOOL cancellable;
@property (nonatomic,   copy) void (^dismissBlock)();

+ (void)presentModalReauthScreen;

@end
