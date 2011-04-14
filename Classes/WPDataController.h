//
//  WPDataController.h
//  WordPress
//
//  Created by Chris Boyd on 6/17/10.
//  Copyright 2010 WordPress. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ASIHTTPRequest.h"
#import "NSString+XMLExtensions.h"
#import "Blog.h"
#import "Post.h"
#import "Page.h"
#import "Comment.h"
#import "WordPressAppDelegate.h"
#import "TouchXML.h"
#import "SFHFKeychainUtils.h"

typedef enum {
	SyncDirectionLocal,
	SyncDirectionRemote,
	SyncDirectionBoth
} SyncDirection;

@interface WPDataController : NSObject {
    BOOL retryOnTimeout;
}

@property (nonatomic, retain) NSError *error;

+ (WPDataController *)sharedInstance;

#pragma mark -
#pragma mark User
- (NSString *)guessXMLRPCForUrl:(NSString *)url;
- (BOOL)checkXMLRPC:(NSString *)xmlrpc username:(NSString *)username password:(NSString *)password;
- (BOOL)authenticateUser:(NSString *)xmlrpc username:(NSString *)username password:(NSString *)password;
- (NSMutableArray *)getBlogsForUrl:(NSString *)xmlrpc username:(NSString *)username password:(NSString *)password;
- (NSMutableArray *)getCategoriesForBlog:(Blog *)blog;

#pragma mark -
#pragma mark Blog
- (NSMutableArray *)getRecentPostsForBlog:(Blog *)blog number:(NSNumber *)number;
- (NSString *)passwordForBlog:(Blog *)blog;
- (NSArray *)wpGetPostFormats:(Blog *)blog;

#pragma mark -
#pragma mark Category
- (int)wpNewCategory:(Category *)category;

#pragma mark -
#pragma mark Post
- (int)mwNewPost:(Post *)post;
- (BOOL)mwEditPost:(Post *)post;
- (BOOL)mwDeletePost:(Post *)post;
- (BOOL)updateSinglePost:(Post *)post;

#pragma mark -
#pragma mark Page
- (NSMutableArray *)wpGetPages:(Blog *)blog number:(NSNumber *)number;
- (int)wpNewPage:(Page *)post;
- (BOOL)wpEditPage:(Page *)post;
- (BOOL)wpDeletePage:(Page *)post;
- (BOOL)updateSinglePage:(Page *)post;

#pragma mark -
#pragma mark Comment

- (NSMutableArray *)wpGetCommentsForBlog:(Blog *)blog;
- (NSNumber *)wpNewComment:(Comment *)comment;
- (BOOL)wpEditComment:(Comment *)comment;
- (BOOL)wpDeleteComment:(Comment *)comment;
- (BOOL)updateSingleComment:(Comment *)comment;

#pragma mark -
#pragma mark Push Notifications
- (void)registerForPushNotifications;
- (void)registerForPushNotificationsInBackground;

#pragma mark -
#pragma mark XMLRPC
- (id)executeXMLRPCRequest:(XMLRPCRequest *)req;

@end
