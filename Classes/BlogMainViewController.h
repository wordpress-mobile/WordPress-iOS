//
//  BlogMainViewController.h
//  WordPress
//
//  Created by Janakiram on 01/09/08.
//  Copyright 2008 Effigent. All rights reserved.
//

#import <UIKit/UIKit.h>

@class BlogDataManager, WordPressAppDelegate, BlogDetailModalViewController, BlogMainViewController,PostsListController,CommentsListController,PagesListController;

@interface BlogMainViewController : UIViewController {
	IBOutlet UITableView *postsTableView;
	NSArray *blogMainMenuContents;
	int awaitingComments;
}


@end
