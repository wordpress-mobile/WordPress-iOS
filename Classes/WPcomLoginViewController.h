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

@protocol WPcomLoginViewControllerDelegate;

@interface WPcomLoginViewController : UITableViewController
@property (assign) id<WPcomLoginViewControllerDelegate> delegate;
@property (nonatomic, assign) BOOL isStatsInitiated;

- (IBAction)cancel:(id)sender;
@end

@protocol WPcomLoginViewControllerDelegate <NSObject>
- (void)loginController:(WPcomLoginViewController *)loginController didAuthenticateWithUsername:(NSString *)username;
- (void)loginControllerDidDismiss:(WPcomLoginViewController *)loginController;
@end