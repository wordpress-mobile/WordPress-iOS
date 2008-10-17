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
	PostsListController *postsListController;	
	CommentsListController *commentsListController;
	PagesListController *pagesListController;
	NSArray *blogMainMenuContents;
	int awaitingComments;
}

@property (nonatomic, retain) PostsListController *postsListController;
@property (nonatomic, retain) CommentsListController *commentsListController;
@property (nonatomic, retain) PagesListController *pagesListController;

@end
