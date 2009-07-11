//
//  BlogViewController.h
//  WordPress
//
//  Created by Josh Bassett on 8/07/09.
//

#import <UIKit/UIKit.h>
#import "PostsListController.h"
#import "PagesViewController.h"
#import "CommentsViewController.h"


@interface BlogViewController : UIViewController <UITabBarControllerDelegate> {
	IBOutlet UITabBarController *tabBarController;
	
	IBOutlet PostsListController *postsViewController;
	IBOutlet PagesViewController *pagesViewController;
	IBOutlet CommentsViewController *commentsViewController;
	
	UIBarButtonItem *backButton;
}

@end
