//
//  SelectWPComBlogVisibilityViewController.h
//  WordPress
//
//  Created by Sendhil Panchadsaram on 4/16/13.
//  Copyright (c) 2013 WordPress. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "WordPressComApi.h"

@protocol SelectWPComBlogVisibilityViewControllerDelegate;
@interface SelectWPComBlogVisibilityViewController : UITableViewController

@property (nonatomic, assign) WordPressComApiBlogVisibility currentBlogVisibility;
@property (nonatomic, weak) id<SelectWPComBlogVisibilityViewControllerDelegate> delegate;

@end

@protocol SelectWPComBlogVisibilityViewControllerDelegate <NSObject>

- (void)selectWPComBlogVisibilityViewController:(SelectWPComBlogVisibilityViewController *)viewController didSelectBlogVisibilitySetting:(WordPressComApiBlogVisibility)visibility;

@end
