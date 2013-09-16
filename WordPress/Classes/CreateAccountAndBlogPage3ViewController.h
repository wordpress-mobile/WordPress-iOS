//
//  CreateAccountAndBlogPage3ViewController.h
//  WordPress
//
//  Created by Sendhil Panchadsaram on 7/24/13.
//  Copyright (c) 2013 WordPress. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BaseNUXViewController.h"

@interface CreateAccountAndBlogPage3ViewController : BaseNUXViewController

@property (nonatomic, copy) void(^onClickedPrevious)(void);
@property (nonatomic, copy) void(^onClickedNext)(void);
@property (nonatomic, copy) void(^onCreatedUser)(NSString *, NSString *);

- (void)setEmail:(NSString *)email;
- (void)setUsername:(NSString *)username;
- (void)setSiteTitle:(NSString *)siteTitle;
- (void)setSiteAddress:(NSString *)siteAddress;
- (void)setLanguage:(NSDictionary *)language;
- (void)setPassword:(NSString *)password;

@end
