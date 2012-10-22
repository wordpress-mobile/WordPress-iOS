//
//  BlogSelectorViewController.h
//  WordPress
//
//  Created by Jorge Bernal on 4/6/11.
//  Copyright 2011 WordPress. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Blog.h"

@class BlogSelectorViewController;
@protocol BlogSelectorViewControllerDelegate <NSObject>

- (void)blogSelectorViewController:(BlogSelectorViewController *)blogSelector didSelectBlog:(Blog *)blog;

@end

@interface BlogSelectorViewController : UITableViewController<NSFetchedResultsControllerDelegate> {
    NSFetchedResultsController *resultsController;
}
@property (nonatomic, weak) id<BlogSelectorViewControllerDelegate> delegate;
@property (nonatomic, strong) Blog *selectedBlog;

@end
