//
//  NewAddUsersBlogViewController.h
//  WordPress
//
//  Created by Sendhil Panchadsaram on 5/2/13.
//  Copyright (c) 2013 WordPress. All rights reserved.
//

#import <UIKit/UIKit.h>

@class NewAddUsersBlogViewController;

@interface NewAddUsersBlogViewController : UIViewController

@property (nonatomic, assign) BOOL isWPCom;
@property (nonatomic, assign) BOOL autoAddSingleBlog;
@property (nonatomic, strong) NSString *username;
@property (nonatomic, strong) NSString *password;
@property (nonatomic, strong) NSString *xmlRPCUrl;
@property (nonatomic, strong) NSString *siteUrl;

@property (nonatomic, copy ) void (^blogAdditionCompleted)(NewAddUsersBlogViewController *);
@property (nonatomic, copy ) void (^onNoBlogsLoaded)(NewAddUsersBlogViewController *);
@property (nonatomic, copy ) void (^onErrorLoading)(NewAddUsersBlogViewController *, NSError *);

@end
