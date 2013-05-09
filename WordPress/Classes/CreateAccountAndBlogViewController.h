//
//  CreateAccountAndBlogViewController.h
//  WordPress
//
//  Created by Sendhil Panchadsaram on 5/7/13.
//  Copyright (c) 2013 WordPress. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef void(^CreateAccountAndBlogViewControllerBlock)(NSString *, NSString *);

@interface CreateAccountAndBlogViewController : UIViewController

@property (nonatomic, copy) CreateAccountAndBlogViewControllerBlock onCreatedUser;

@end
