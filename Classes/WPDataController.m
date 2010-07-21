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
@synthesize appDelegate;

- (id) init {
	self = [super init];
	appDelegate = [WordPressAppDelegate sharedWordPressApp];
	if (self == nil)
		return nil;
	return self;
}

- (void)dealloc {
	[appDelegate release];
	[super dealloc];
}

+ (WPDataController *)sharedInstance {
	static WPDataController *instance = nil;
	if (instance == nil) instance = [[WPDataController alloc] init];
	return instance;
}

#pragma mark -
#pragma mark User

- (BOOL)authenticateUser:(NSString *)xmlrpc username:(NSString *)username password:(NSString *)password {
	if([self getBlogsForUsername:xmlrpc username:username password:password] != nil)
		return YES;
	else
		return NO;
}

- (NSMutableArray *)getBlogsForUsername:(NSString *)xmlrpc username:(NSString *)username password:(NSString *)password {
	NSMutableArray *usersBlogs = [[NSMutableArray alloc] init];
	
	XMLRPCRequest *xmlrpcUsersBlogs = [[XMLRPCRequest alloc] initWithHost:[NSURL URLWithString:xmlrpc]];
	[xmlrpcUsersBlogs setMethod:@"wp.getUsersBlogs" withObjects:[NSArray arrayWithObjects:username, password, nil]];
	NSArray *usersBlogsData = [self executeXMLRPCRequest:xmlrpcUsersBlogs];
	
	if([usersBlogsData class] != [NSError class]) {
		for(NSDictionary *dictBlog in usersBlogsData) {
			Blog *blog = [[Blog alloc] init];
			if((int)[dictBlog valueForKey:@"isAdmin"] == 1) {
				blog.isAdmin = [[dictBlog valueForKey:@"isAdmin"] boolValue];
			}
			blog.blogID = [dictBlog valueForKey:@"blogid"];
			blog.blogName = (NSString *)[dictBlog valueForKey:@"blogName"];
			blog.url = (NSString *)[dictBlog valueForKey:@"url"];
			blog.xmlrpc = (NSString *)[dictBlog valueForKey:@"xmlrpc"];
			blog.username = username;
			blog.password = password;
			[usersBlogs addObject:blog];
		}
	}
	else {
		usersBlogs = nil;
	}
	return usersBlogs;
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

#pragma mark -
#pragma mark XMLRPC

- (id)executeXMLRPCRequest:(XMLRPCRequest *)req {
	XMLRPCResponse *userInfoResponse = nil;
	userInfoResponse = [XMLRPCConnection sendSynchronousXMLRPCRequest:req];
	
    NSError *err = [self errorWithResponse:userInfoResponse];
    if (err)
        return err;
	
    return [userInfoResponse object];
}

- (NSError *)errorWithResponse:(XMLRPCResponse *)res {
    NSError *err = nil;
	
    if ([res isKindOfClass:[NSError class]]) {
        err = (NSError *)res;
    } else {
        if ([res isFault]) {
            NSDictionary *usrInfo = [NSDictionary dictionaryWithObjectsAndKeys:[res fault], NSLocalizedDescriptionKey, nil];
            err = [NSError errorWithDomain:@"org.wordpress.iphone" code:[[res code] intValue] userInfo:usrInfo];
        }
		
        if ([res isParseError]) {
            err = [res object];
        }
    }
	
    return err;
}

@end
