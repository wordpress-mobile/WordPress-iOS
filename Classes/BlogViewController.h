//
//  BlogViewController.h
//  WordPress
//
//  Created by Janakiram on 01/09/08.
//

#import <UIKit/UIKit.h>

@class BlogDataManager, WordPressAppDelegate, EditBlogViewController, BlogViewController, PostsListController,CommentsListController,PagesViewController;

@interface BlogViewController : UIViewController {
	IBOutlet UITableView *postsTableView;
	NSArray *blogMainMenuContents;
	int awaitingComments;
}

@end
