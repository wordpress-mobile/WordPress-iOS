#import <UIKit/UIKit.h>

@class Blog, WPAccount;

@interface JetpackLoginViewController : UIViewController

+ (instancetype)instantiate;

- (void)setBlog:(Blog *)blog;

@property (nonatomic, assign) BOOL canBeSkipped;

@property (copy, nonatomic) NSString *username;
@property (copy, nonatomic) NSString *email;
@property (strong, nonatomic) NSNumber *siteID;

@property (nonatomic, copy) void (^completionBlock)(WPAccount *account);

@end
