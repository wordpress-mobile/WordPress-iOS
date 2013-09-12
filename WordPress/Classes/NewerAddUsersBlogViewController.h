//
//  NewerAddUsersBlogViewController.h
//  WordPress
//
//  Created by Sendhil Panchadsaram on 7/24/13.
//  Copyright (c) 2013 WordPress. All rights reserved.
//

#import <UIKit/UIKit.h>

@class WPAccount;
@interface NewerAddUsersBlogViewController : UIViewController

@property (nonatomic, assign) BOOL autoAddSingleBlog;
@property (nonatomic, strong) NSString *siteUrl;
@property (nonatomic, strong) WPAccount *account;

@property (nonatomic, copy ) void (^blogAdditionCompleted)(NewerAddUsersBlogViewController *);
@property (nonatomic, copy ) void (^onNoBlogsLoaded)(NewerAddUsersBlogViewController *);
@property (nonatomic, copy ) void (^onErrorLoading)(NewerAddUsersBlogViewController *, NSError *);

@end
