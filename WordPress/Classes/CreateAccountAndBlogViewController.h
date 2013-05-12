//
//  CreateAccountAndBlogViewController.h
//  WordPress
//
//  Created by Sendhil Panchadsaram on 5/7/13.
//  Copyright (c) 2013 WordPress. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BaseNUXViewController.h"

@interface CreateAccountAndBlogViewController : BaseNUXViewController

@property (nonatomic, copy) void(^onCreatedUser)(NSString *, NSString *);

@end
