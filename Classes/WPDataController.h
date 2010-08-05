//
//  WPDataController.h
//  WordPress
//
//  Created by Chris Boyd on 6/17/10.
//  Copyright 2010 WordPress. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "WPDataControllerDelegate.h"
#import "NSString+XMLExtensions.h"
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
// XMLRPC
- (id)executeXMLRPCRequest:(XMLRPCRequest *)req;
- (NSError *)errorWithResponse:(XMLRPCResponse *)res;

@end
