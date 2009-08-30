//
//  BlogViewController.h
//  WordPress
//
//  Created by Josh Bassett on 8/07/09.
//

#import <UIKit/UIKit.h>
#import "PostsViewController.h"
#import "PagesViewController.h"
#import "CommentsViewController.h"

@interface BlogViewController : UIViewController <UITabBarControllerDelegate> {
    IBOutlet UITabBarController *tabBarController;

    IBOutlet PostsViewController *postsViewController;
    IBOutlet PagesViewController *pagesViewController;
    IBOutlet CommentsViewController *commentsViewController;
}

@end
