//
//  CreateAccountAndBlogPage2ViewController.h
//  WordPress
//
//  Created by Sendhil Panchadsaram on 7/24/13.
//  Copyright (c) 2013 WordPress. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BaseNUXViewController.h"

@interface CreateAccountAndBlogPage2ViewController : BaseNUXViewController

@property (nonatomic, weak) UIView *containingView;
@property (nonatomic, copy) void(^onClickedPrevious)(void);
@property (nonatomic, copy) void(^onClickedNext)(void);
@property (nonatomic, copy) void(^onValidatedSiteFields)(NSString *, NSString *, NSDictionary *);

- (void)setDefaultSiteAddress:(NSString *)siteAddress;

@end
