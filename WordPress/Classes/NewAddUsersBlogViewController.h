//
//  NewAddUsersBlogViewController.h
//  WordPress
//
//  Created by Sendhil Panchadsaram on 5/2/13.
//  Copyright (c) 2013 WordPress. All rights reserved.
//

#import <UIKit/UIKit.h>

@class WPAccount;
@interface NewAddUsersBlogViewController : UIViewController

@property (nonatomic, assign) BOOL autoAddSingleBlog;
@property (nonatomic, strong) NSString *siteUrl;
@property (nonatomic, strong) WPAccount *account;

@property (nonatomic, copy ) void (^blogAdditionCompleted)(NewAddUsersBlogViewController *);
@property (nonatomic, copy ) void (^onNoBlogsLoaded)(NewAddUsersBlogViewController *);
@property (nonatomic, copy ) void (^onErrorLoading)(NewAddUsersBlogViewController *, NSError *);

@end
