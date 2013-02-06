//
//  WPcomLoginViewController.h
//  WordPress
//
//  Created by Chris Boyd on 7/19/10.
//

#import <UIKit/UIKit.h>
#import "AddUsersBlogsViewController.h"
#import "UITableViewActivityCell.h"
#import "WordPressAppDelegate.h"
#import "Blog.h"

@protocol WPcomLoginViewControllerDelegate;

@interface WPcomLoginViewController : UITableViewController

@property (weak) id<WPcomLoginViewControllerDelegate> delegate;
@property (nonatomic, assign) BOOL isCancellable;
@property (nonatomic, assign) BOOL dismissWhenFinished;
@property (nonatomic, strong) NSString *predefinedUsername;
@property (nonatomic, strong) Blog *blog;

- (IBAction)cancel:(id)sender;

+ (void)presentLoginScreenWithSuccess:(void (^)(NSString *username, NSString *password))success cancel:(void (^)())cancel;

@end

@protocol WPcomLoginViewControllerDelegate <NSObject>
- (void)loginController:(WPcomLoginViewController *)loginController didAuthenticateWithUsername:(NSString *)username;
- (void)loginControllerDidDismiss:(WPcomLoginViewController *)loginController;
@end