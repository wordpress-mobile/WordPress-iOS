//
//  WPDataController.h
//  WordPress
//
//  Created by Chris Boyd on 6/17/10.
//  Copyright 2010 WordPress. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "WPDataControllerDelegate.h"
#import "XMLRPCConnection.h"
#import "XMLRPCRequest.h"
#import "XMLRPCResponse.h"
#import "NSString+XMLExtensions.h"
#import "RegexKitLite.h"
#import "Blog.h"
#import "Post.h"
#import "Page.h"
#import "Comment.h"
#import "WordPressAppDelegate.h"

typedef enum {
	SyncDirectionLocal,
	SyncDirectionRemote,
	SyncDirectionBoth
} SyncDirection;

@interface WPDataController : NSObject {
	id<WPDataControllerDelegate> delegate;
	WordPressAppDelegate *appDelegate;
}

@property (nonatomic, retain) WordPressAppDelegate *appDelegate;

+ (WPDataController *)sharedInstance;

// User
- (BOOL)authenticateUser:(NSString *)xmlrpc username:(NSString *)username password:(NSString *)password;
- (NSMutableArray *)getBlogsForUrl:(NSString *)xmlrpc username:(NSString *)username password:(NSString *)password;

// Blog
- (Blog *)getBlog:(int)blogID andPopulate:(BOOL)andPopulate;
- (BOOL)addBlog:(Blog *)blog direction:(SyncDirection *)direction;
- (BOOL)updateBlog:(Blog *)blog direction:(SyncDirection *)direction;
- (BOOL)deleteBlog:(Blog *)blog direction:(SyncDirection *)direction;

// Post
- (Post *)getPost:(int)postID;
- (BOOL)addPost:(Post *)post direction:(SyncDirection *)direction;
- (BOOL)updatePost:(Post *)post direction:(SyncDirection *)direction;
- (BOOL)deletePost:(Post *)post direction:(SyncDirection *)direction;

// Page
- (Page *)getPage:(int)pageID;
- (BOOL)addPage:(Page *)page direction:(SyncDirection *)direction;
- (BOOL)updatePage:(Page *)page direction:(SyncDirection *)direction;
- (BOOL)deletePage:(Page *)page direction:(SyncDirection *)direction;

// Comment
- (Comment *)getComment:(int)commentID;
- (BOOL)addComment:(Comment *)comment direction:(SyncDirection *)direction;
- (BOOL)updateComment:(Comment *)comment direction:(SyncDirection *)direction;
- (BOOL)deleteComment:(Comment *)comment direction:(SyncDirection *)direction;

// XMLRPC
- (id)executeXMLRPCRequest:(XMLRPCRequest *)req;
- (NSError *)errorWithResponse:(XMLRPCResponse *)res;

@end
