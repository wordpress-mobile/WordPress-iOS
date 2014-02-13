//
//  CreateAccountAndBlogPage1ViewController.h
//  WordPress
//
//  Created by Sendhil Panchadsaram on 7/24/13.
//  Copyright (c) 2013 WordPress. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BaseNUXViewController.h"

@interface CreateAccountAndBlogPage1ViewController : BaseNUXViewController

@property (nonatomic, copy) void (^onClickedNext)(void);
@property (nonatomic, copy) void (^onValidatedUserFields)(NSString *, NSString *, NSString *);
@property (nonatomic, weak) UIView *containingView;

@end
