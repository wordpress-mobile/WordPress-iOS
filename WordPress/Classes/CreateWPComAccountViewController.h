//
//  CreateWPComAccountViewController.h
//  WordPress
//
//  Created by Sendhil Panchadsaram on 4/5/13.
//  Copyright (c) 2013 WordPress. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol CreateWPComAccountViewControllerDelegate;
@interface CreateWPComAccountViewController : UITableViewController

@property (nonatomic, weak) id<CreateWPComAccountViewControllerDelegate> delegate;

@end

@protocol CreateWPComAccountViewControllerDelegate <NSObject>

- (void)createdAndSignedInAccountWithUserName:(NSString *)userName;
- (void)createdAccountWithUserName:(NSString *)userName;

@end
