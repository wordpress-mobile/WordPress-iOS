//
//  NewAddUsersBlogViewController.h
//  WordPress
//
//  Created by Sendhil Panchadsaram on 5/2/13.
//  Copyright (c) 2013 WordPress. All rights reserved.
//

#import <UIKit/UIKit.h>

@class NewAddUsersBlogViewController;
typedef void(^AddUsersBlogViewControllerBlock)(NewAddUsersBlogViewController *);
typedef void(^AddUsersBlogViewControllerErrorBlock)(NewAddUsersBlogViewController *, NSError *);

@interface NewAddUsersBlogViewController : UITableViewController

@property (nonatomic, assign) BOOL isWPCom;
@property (nonatomic, assign) BOOL autoAddSingleBlog;
@property (nonatomic, strong) NSString *username;
@property (nonatomic, strong) NSString *password;
@property (nonatomic, strong) NSString *url;

@property (nonatomic, copy) AddUsersBlogViewControllerBlock blogAdditionCompleted;
@property (nonatomic, copy) AddUsersBlogViewControllerBlock onNoBlogsLoaded;
@property (nonatomic, copy) AddUsersBlogViewControllerErrorBlock onErrorLoading;

@end
