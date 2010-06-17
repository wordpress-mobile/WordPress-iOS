//
//  WPDataController.m
//  WordPress
//
//  Created by Chris Boyd on 6/17/10.
//  Copyright 2010 WordPress. All rights reserved.
//

#import "WPDataController.h"

@interface WPDataController()
- (id) init;
@end

@implementation WPDataController

- (id) init {
	self = [super init];
	if (self == nil)
		return nil;
	return self;
}

+ (WPDataController *)sharedInstance {
	static WPDataController *instance = nil;
	if (instance == nil) instance = [[WPDataController alloc] init];
	return instance;
}

#pragma mark -
#pragma mark Blog

- (Blog *)getBlog:(int)blogID andPopulate:(BOOL)andPopulate {
	Blog *blog = [[Blog alloc] init];
	return blog;
}

- (BOOL)addBlog:(Blog *)blog direction:(SyncDirection *)direction {
	return YES;
}

- (BOOL)updateBlog:(Blog *)blog direction:(SyncDirection *)direction {
	return YES;
}

- (BOOL)deleteBlog:(Blog *)blog direction:(SyncDirection *)direction {
	return YES;
}

#pragma mark -
#pragma mark Post

- (Post *)getPost:(int)postID {
	Post *post = [[Post alloc] init];
	return post;
}

- (BOOL)addPost:(Post *)post direction:(SyncDirection *)direction {
	return YES;
}

- (BOOL)updatePost:(Post *)post direction:(SyncDirection *)direction {
	return YES;
}

- (BOOL)deletePost:(Post *)post direction:(SyncDirection *)direction {
	return YES;
}

#pragma mark -
#pragma mark Page

- (Page *)getPage:(int)pageID {
	Page *page = [[Page alloc] init];
	return page;
}

- (BOOL)addPage:(Page *)page direction:(SyncDirection *)direction {
	return YES;
}

- (BOOL)updatePage:(Page *)page direction:(SyncDirection *)direction {
	return YES;
}

- (BOOL)deletePage:(Page *)page direction:(SyncDirection *)direction {
	return YES;
}

#pragma mark -
#pragma mark Comment

- (Comment *)getComment:(int)commentID {
	Comment *comment = [[Comment alloc] init];
	return comment;
}

- (BOOL)addComment:(Comment *)comment direction:(SyncDirection *)direction {
	return YES;
}

- (BOOL)updateComment:(Comment *)comment direction:(SyncDirection *)direction {
	return YES;
}

- (BOOL)deleteComment:(Comment *)comment direction:(SyncDirection *)direction {
	return YES;
}

@end
