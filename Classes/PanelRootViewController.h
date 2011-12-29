//
//  PanelRootViewController.h
//  WordPress
//
//  Created by Brad Angelcyk on 12/28/11.
//  Copyright (c) 2011 WordPress. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "WordPressAppDelegate.h"
#import "BlogsViewController.h"

@class BlogsViewController;
@class StackScrollViewController;

@class UIViewExt;

@interface PanelRootViewController : UIViewController {
    UIViewExt* rootView;
    UIView* leftMenuView;
    UIView* rightSlideView;

    BlogsViewController *blogsViewController;
    StackScrollViewController* stackScrollViewController;
    
    WordPressAppDelegate *delegate;
}

@property (nonatomic, retain) BlogsViewController* blogsViewController;
@property (nonatomic, retain) StackScrollViewController* stackScrollViewController;
@property (nonatomic, retain) WordPressAppDelegate *delegate;

@end
