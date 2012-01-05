//
//  PSStackedViewRootViewController.h
//  WordPress
//
//  Created by Brad Angelcyk on 1/4/12.
//  Copyright (c) 2012 WordPress. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "WordPressAppDelegate.h"
#import "UIView+PSSizes.h"
#import "BlogsViewController.h"

@interface PSStackedViewRootViewController : UIViewController {
    UIView* rootView;
    UIView* leftMenuView;
    UIView* rightSlideView;
    
    WordPressAppDelegate *delegate;
    
    BlogsViewController *blogsViewController;
}

@property (nonatomic, retain) WordPressAppDelegate *delegate;
@property (nonatomic, retain) BlogsViewController* blogsViewController;

@end
