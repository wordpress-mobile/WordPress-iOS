//
//  NewCreateAccountAndBlogViewController.h
//  WordPress
//
//  Created by Sendhil Panchadsaram on 7/24/13.
//  Copyright (c) 2013 WordPress. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface NewCreateAccountAndBlogViewController : UIViewController

@property (nonatomic, copy) void(^onCreatedUser)(NSString *, NSString *);

@end
