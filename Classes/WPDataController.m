//
//  WPDataController.m
//  WordPress
//
//  Created by Chris Boyd on 6/17/10.
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
	if((xmlrpc != nil) && (username != nil) && (password != nil) && ([self getBlogsForUrl:xmlrpc username:username password:password] != nil))
		return YES;
	else
		return NO;
}

- (NSMutableArray *)getBlogsForUrl:(NSString *)xmlrpc username:(NSString *)username password:(NSString *)password {
	NSMutableArray *usersBlogs = [[NSMutableArray alloc] init];
		
	@try {
		XMLRPCRequest *xmlrpcUsersBlogs = [[XMLRPCRequest alloc] initWithHost:[NSURL URLWithString:xmlrpc]];
		[xmlrpcUsersBlogs setMethod:@"wp.getUsersBlogs" withObjects:[NSArray arrayWithObjects:username, password, nil]];
		NSArray *usersBlogsData = [self executeXMLRPCRequest:xmlrpcUsersBlogs];
		
		if([usersBlogsData isKindOfClass:[NSArray class]]) {
			for(NSDictionary *dictBlog in usersBlogsData) {
				Blog *blog = [[Blog alloc] init];
				if((int)[dictBlog valueForKey:@"isAdmin"] == 1) {
					blog.isAdmin = [[dictBlog valueForKey:@"isAdmin"] boolValue];
				}
				blog.username = username;
				blog.password = password;
				if([[dictBlog objectForKey:@"blogid"] isKindOfClass:[NSString class]])
					[blog setBlogID:[dictBlog objectForKey:@"blogid"]];
				else
					[blog setBlogID:[[dictBlog objectForKey:@"blogid"] stringValue]];
				blog.blogName = [NSString decodeXMLCharactersIn:[dictBlog valueForKey:@"blogName"]];
				blog.url = [dictBlog valueForKey:@"url"];
				
				NSRange textRange = [blog.url.lowercaseString rangeOfString:@"wordpress.com"];
				if(textRange.location != NSNotFound)
				{
					blog.hostURL = [NSString stringWithFormat:@"%@_%@", 
								 blog.username, 
								 [blog.url stringByReplacingOccurrencesOfRegex:@"http(s?)://" withString:@""]];
				}
				else {
					blog.hostURL = [blog.url stringByReplacingOccurrencesOfRegex:@"http(s?)://" withString:@""];
				}
				
				if([blog.hostURL hasSuffix:@"/"])
					blog.hostURL = [blog.hostURL substringToIndex:[blog.hostURL length] - 1];
				blog.xmlrpc = [dictBlog valueForKey:@"xmlrpc"];
				[usersBlogs addObject:blog];
				[blog release];
			}
		}
		else {
			usersBlogs = nil;
		}
	}
	@catch (NSException * e) {}
	@finally {}
	
	return usersBlogs;
}

#pragma mark -
#pragma mark Blog

- (Blog *)getBlog:(int)blogID andPopulate:(BOOL)andPopulate {
	Blog *blog = [[[Blog alloc] init] autorelease];
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
	Post *post = [[[Post alloc] init] autorelease];
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
	Page *page = [[[Page alloc] init] autorelease];
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
	Comment *comment = [[[Comment alloc] init] autorelease];
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
