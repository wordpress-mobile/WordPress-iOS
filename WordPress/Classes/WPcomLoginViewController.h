#import <UIKit/UIKit.h>

@protocol WPcomLoginViewControllerDelegate;

@class WPAccount;

@interface WPcomLoginViewController : UITableViewController

@property (weak) id<WPcomLoginViewControllerDelegate> delegate;

// Pre-filled username. Used for signup.
@property (nonatomic, strong) NSString *predefinedUsername;

+ (void)presentLoginScreen;

@end

@protocol WPcomLoginViewControllerDelegate <NSObject>
- (void)loginController:(WPcomLoginViewController *)loginController didAuthenticateWithAccount:(WPAccount *)account;
- (void)loginControllerDidDismiss:(WPcomLoginViewController *)loginController;
@end