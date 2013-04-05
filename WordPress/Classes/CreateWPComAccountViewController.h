//
//  CreateWPComAccountViewController.h
//  WordPress
//
//  Created by Sendhil Panchadsaram on 3/27/13.
//  Copyright (c) 2013 WordPress. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol CreateWPComAccountViewControllerDelegate;
@interface CreateWPComAccountViewController : UIViewController

@property (nonatomic, weak) id<CreateWPComAccountViewControllerDelegate> delegate;

@end

@protocol CreateWPComAccountViewControllerDelegate <NSObject>

- (void)createdAndSignedInAccountWithUserName:(NSString *)userName;
- (void)createdAccountWithUserName:(NSString *)userName;

@end
