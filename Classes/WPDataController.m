//
//  WPDataController.m
//  WordPress
//
//  Created by Chris Boyd on 6/17/10.
//

#import "WPDataController.h"

@interface WPDataController(PrivateMethods)
- (id) init;
- (NSMutableDictionary *)getXMLRPCDictionaryForPost:(AbstractPost *)post;
- (NSArray *)getXMLRPCArgsForBlog:(Blog *)blog  withExtraArgs:(NSArray *)args;
- (id)executeXMLRPCRequest:(XMLRPCRequest *)req;
- (NSError *)errorWithResponse:(XMLRPCResponse *)res;
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

- (BOOL)checkXMLRPC:(NSString *)xmlrpc username:(NSString *)username password:(NSString *)password {
	BOOL result = NO;
	
	ASIHTTPRequest *request = [[ASIHTTPRequest alloc] initWithURL:[NSURL URLWithString:xmlrpc]];
	[request setRequestMethod:@"POST"];
	[request setShouldPresentCredentialsBeforeChallenge:NO];
	[request setShouldPresentAuthenticationDialog:YES];
	[request setUseKeychainPersistence:YES];
	
	XMLRPCRequest *xmlrpcRequest = [[XMLRPCRequest alloc] initWithHost:[NSURL URLWithString:xmlrpc]];
	[xmlrpcRequest setMethod:@"wp.getUsersBlogs" withObjects:[NSArray arrayWithObjects:username, password, nil]];
	[request appendPostData:[[xmlrpcRequest source] dataUsingEncoding:NSUTF8StringEncoding]];
	[request startSynchronous];
	[xmlrpcRequest release];
	
	NSError *error = [request error];
	if (!error) {
		CXMLDocument *xml = [[[CXMLDocument alloc] initWithXMLString:[request responseString] options:CXMLDocumentTidyXML error:nil] autorelease];
		CXMLElement *node = [[xml nodesForXPath:@"//methodResponse" error:nil] objectAtIndex:0];
		if(node != nil)
			result = YES;
		else
			result = NO;
	}
    [request release];
	
	return result;
}

- (BOOL)authenticateUser:(NSString *)xmlrpc username:(NSString *)username password:(NSString *)password {
	BOOL result = NO;
	if((xmlrpc != nil) && (username != nil) && (password != nil)) {
		if([self getBlogsForUrl:xmlrpc username:username password:password] != nil)
			result = YES;
	}
	return result;
}

- (NSMutableArray *)getBlogsForUrl:(NSString *)xmlrpc username:(NSString *)username password:(NSString *)password {
	NSMutableArray *usersBlogs = [[NSMutableArray alloc] init];
		
	@try {
		XMLRPCRequest *xmlrpcUsersBlogs = [[XMLRPCRequest alloc] initWithHost:[NSURL URLWithString:xmlrpc]];
		[xmlrpcUsersBlogs setMethod:@"wp.getUsersBlogs" withObjects:[NSArray arrayWithObjects:username, password, nil]];
		NSArray *usersBlogsData = [self executeXMLRPCRequest:xmlrpcUsersBlogs];
		
		if([usersBlogsData isKindOfClass:[NSArray class]]) {
            [usersBlogs release];
            usersBlogs = [NSArray arrayWithArray:usersBlogsData];
		}
		else if([usersBlogsData isKindOfClass:[NSError class]]) {
			NSError *error = (NSError *)usersBlogsData;
			NSString *errorMessage = [error localizedDescription];
			
			usersBlogs = nil;
			
			if([errorMessage isEqualToString:@"The operation couldn’t be completed. (NSXMLParserErrorDomain error 4.)"])
				errorMessage = @"Your blog's XML-RPC endpoint was found but it isn't communicating properly. Try disabling plugins or contacting your host.";
			//else if([errorMessage isEqualToString:@"Bad login/pass combination."])
				//errorMessage = nil;
			
			if(errorMessage != nil)
				[appDelegate showAlertWithTitle:@"XML-RPC Error" message:errorMessage];
		}
		else {
			usersBlogs = nil;
			NSLog(@"getBlogsForUrl failed: %@", usersBlogsData);
		}
	}
	@catch (NSException * e) {
		usersBlogs = nil;
		NSLog(@"getBlogsForUrl failed: %@", e);
	}
	
	return usersBlogs;
}

#pragma mark -
#pragma mark Blog

- (NSString *)passwordForBlog:(Blog *)blog {
    NSError *error;
    return [SFHFKeychainUtils getPasswordForUsername:blog.username
                                      andServiceName:blog.url
                                               error:&error];
}

- (NSMutableArray *)getRecentPostsForBlog:(Blog *)blog {
    XMLRPCRequest *xmlrpcRequest = [[XMLRPCRequest alloc] initWithHost:[NSURL URLWithString:blog.xmlrpc]];
    // TODO: use app-wide setting for number of posts
    NSArray *args = [NSArray arrayWithObject:[NSNumber numberWithInt:10]];
	[xmlrpcRequest setMethod:@"metaWeblog.getRecentPosts" withObjects:[self getXMLRPCArgsForBlog:blog withExtraArgs:args]];
    NSArray *recentPosts = [self executeXMLRPCRequest:xmlrpcRequest];
	[xmlrpcRequest release];
    
    if ([recentPosts isKindOfClass:[NSError class]]) {
        NSLog(@"Couldn't get recent posts: %@", [(NSError *)recentPosts localizedDescription]);
        return [NSMutableArray array];
    }
    return [NSMutableArray arrayWithArray:recentPosts];
}

- (NSMutableArray *)getCategoriesForBlog:(Blog *)blog {
    XMLRPCRequest *xmlrpcRequest = [[XMLRPCRequest alloc] initWithHost:[NSURL URLWithString:blog.xmlrpc]];
	[xmlrpcRequest setMethod:@"wp.getCategories" withObjects:[self getXMLRPCArgsForBlog:blog withExtraArgs:nil]];
	
    NSArray *categories = [self executeXMLRPCRequest:xmlrpcRequest];
    [xmlrpcRequest release];

    if ([categories isKindOfClass:[NSError class]]) {
        NSLog(@"Couldn't get categories: %@", [(NSError *)categories localizedDescription]);
        return [NSMutableArray array];
    }

    return [NSMutableArray arrayWithArray:categories];
}

#pragma mark -
#pragma mark Category
- (int)wpNewCategory:(Category *)category {
    XMLRPCRequest *request = [[XMLRPCRequest alloc] initWithHost:[NSURL URLWithString:category.blog.xmlrpc]];
    NSDictionary *categoryDict = [NSDictionary dictionaryWithObjectsAndKeys:category.categoryName,
                                  @"name",
                                  category.parentID,
                                  @"parent_id",
                                  nil];
    NSArray *args = [NSArray arrayWithObject:categoryDict];
    [request setMethod:@"wp.newCategory" withObjects:[self getXMLRPCArgsForBlog:category.blog withExtraArgs:args]];
    NSNumber *categoryID = [self executeXMLRPCRequest:request];
    if ([category isKindOfClass:[NSError class]]) {
        NSLog(@"Error creating category: %@", categoryID);
        return -1;
    } else {
        return [categoryID intValue];
    }

}

#pragma mark -
#pragma mark Post

- (NSMutableDictionary *)getXMLRPCDictionaryForPost:(AbstractPost *)post {
    NSMutableDictionary *postParams = [NSMutableDictionary dictionary];
    if (post.postTitle != nil)
        [postParams setObject:post.postTitle forKey:@"title"];
    if (post.content != nil)
        [postParams setObject:post.content forKey:@"description"];
    if ([post isKindOfClass:[Post class]]) {
        if ([post valueForKey:@"tags"] != nil)
            [postParams setObject:[post valueForKey:@"tags"] forKey:@"mt_keywords"];
        if ([post valueForKey:@"categories"] != nil) {
            NSMutableSet *categories = [post mutableSetValueForKey:@"categories"];
            NSMutableArray *categoryNames = [NSMutableArray arrayWithCapacity:[categories count]];
            for (Category *cat in categories) {
                [categoryNames addObject:cat.categoryName];
            }
            [postParams setObject:categoryNames forKey:@"categories"];
        }
    }
    if (post.status == nil)
        post.status = @"publish";
    [postParams setObject:post.status forKey:@"post_status"];
    
	if (post.date_created_gmt == nil) {
        post.date_created_gmt = [DateUtils localDateToGMTDate:[NSDate date]];
    }
	[postParams setObject:post.date_created_gmt forKey:@"date_created_gmt"];
	
    if (post.password != nil)
        [postParams setObject:post.password forKey:@"wp_password"];
    return postParams;
}

// Returns post ID, -1 if unsuccessful
- (int)mwNewPost:(Post *)post {
    XMLRPCRequest *xmlrpcRequest = [[XMLRPCRequest alloc] initWithHost:[NSURL URLWithString:post.blog.xmlrpc]];
    NSMutableDictionary *postParams = [self getXMLRPCDictionaryForPost:post];

    [xmlrpcRequest setMethod:@"metaWeblog.newPost" withObjects:[self getXMLRPCArgsForBlog:post.blog withExtraArgs:[NSArray arrayWithObject:postParams]]];

    id result = [self executeXMLRPCRequest:xmlrpcRequest];
    if ([result isKindOfClass:[NSError class]]) {
        return -1;
    }

    // Result should be a string with the post ID
    NSLog(@"newPost result: %@", result);
    return [result intValue];
}

- (BOOL)mwEditPost:(Post *)post {
    if (post.postID == nil) {
        return NO;
    }
    
    XMLRPCRequest *xmlrpcRequest = [[XMLRPCRequest alloc] initWithHost:[NSURL URLWithString:post.blog.xmlrpc]];
    NSMutableDictionary *postParams = [self getXMLRPCDictionaryForPost:post];
    NSArray *args = [NSArray arrayWithObjects:post.postID, post.blog.username, [self passwordForBlog:post.blog], postParams, nil];
    
    [xmlrpcRequest setMethod:@"metaWeblog.editPost" withObjects:args];
    id result = [self executeXMLRPCRequest:xmlrpcRequest];
    if ([result isKindOfClass:[NSError class]]) {
        NSLog(@"mwEditPost failed: %@", result);
        return NO;
    } else {
        return YES;
    }
}

- (BOOL)mwDeletePost:(Post *)post {
    if (post.postID == nil) {
        // No post ID means no need to delete anything in the server
        // so we return YES to allow the Post to be deleted from the app
        return YES;
    }

    XMLRPCRequest *xmlrpcRequest = [[XMLRPCRequest alloc] initWithHost:[NSURL URLWithString:post.blog.xmlrpc]];
    NSArray *args = [NSArray arrayWithObjects:@"unused", post.postID, post.blog.username, [self passwordForBlog:post.blog], nil];

    [xmlrpcRequest setMethod:@"metaWeblog.deletePost" withObjects:args];
    id result = [self executeXMLRPCRequest:xmlrpcRequest];
    if ([result isKindOfClass:[NSError class]]) {
        NSLog(@"mwEditPost failed: %@", result);
        return NO;
    } else {
        return YES;
    }
}

#pragma mark -
#pragma mark Page
- (NSMutableArray *)wpGetPages:(Blog *)blog {
    XMLRPCRequest *xmlrpcRequest = [[XMLRPCRequest alloc] initWithHost:[NSURL URLWithString:blog.xmlrpc]];
    // TODO: use app-wide setting for number of posts
    NSArray *args = [NSArray arrayWithObject:[NSNumber numberWithInt:10]];
	[xmlrpcRequest setMethod:@"wp.getPages" withObjects:[self getXMLRPCArgsForBlog:blog withExtraArgs:args]];
    NSArray *recentPages = [self executeXMLRPCRequest:xmlrpcRequest];
	[xmlrpcRequest release];
    if ([recentPages isKindOfClass:[NSError class]]) {
        return [NSMutableArray array];
    }    
    
    return [NSMutableArray arrayWithArray:recentPages];
}

// Returns post ID, -1 if unsuccessful
- (int)wpNewPage:(Page *)post {
    XMLRPCRequest *xmlrpcRequest = [[XMLRPCRequest alloc] initWithHost:[NSURL URLWithString:post.blog.xmlrpc]];
    NSMutableDictionary *postParams = [self getXMLRPCDictionaryForPost:post];
    
    [xmlrpcRequest setMethod:@"wp.newPage" withObjects:[self getXMLRPCArgsForBlog:post.blog withExtraArgs:[NSArray arrayWithObject:postParams]]];
    
    id result = [self executeXMLRPCRequest:xmlrpcRequest];
    if ([result isKindOfClass:[NSError class]]) {
        return -1;
    }
    
    // Result should be a string with the post ID
    NSLog(@"wpNewPage result: %@", result);
    return [result intValue];
}

- (BOOL)wpEditPage:(Page *)post {
    if (post.postID == nil) {
        return NO;
    }
    
    XMLRPCRequest *xmlrpcRequest = [[XMLRPCRequest alloc] initWithHost:[NSURL URLWithString:post.blog.xmlrpc]];
    NSMutableDictionary *postParams = [self getXMLRPCDictionaryForPost:post];
    NSArray *args = [NSArray arrayWithObjects:post.blog.blogID, post.postID, post.blog.username, [self passwordForBlog:post.blog], postParams, nil];
    
    [xmlrpcRequest setMethod:@"wp.editPage" withObjects:args];
    id result = [self executeXMLRPCRequest:xmlrpcRequest];
    if ([result isKindOfClass:[NSError class]]) {
        NSLog(@"wpEditPage failed: %@", result);
        return NO;
    } else {
        return YES;
    }
}

- (BOOL)wpDeletePage:(Page *)post {
    if (post.postID == nil) {
        // No post ID means no need to delete anything in the server
        // so we return YES to allow the Post to be deleted from the app
        return YES;
    }
    
    XMLRPCRequest *xmlrpcRequest = [[XMLRPCRequest alloc] initWithHost:[NSURL URLWithString:post.blog.xmlrpc]];
    NSArray *args = [NSArray arrayWithObjects:post.blog.blogID, post.blog.username, [self passwordForBlog:post.blog], post.postID, nil];
    
    [xmlrpcRequest setMethod:@"wp.deletePage" withObjects:args];
    id result = [self executeXMLRPCRequest:xmlrpcRequest];
    if ([result isKindOfClass:[NSError class]]) {
        NSLog(@"wpDeletePage failed: %@", result);
        return NO;
    } else {
        return YES;
    }
}

#pragma mark -
#pragma mark Comment

- (NSMutableDictionary *)getXMLRPCDictionaryForComment:(Comment *)comment {
    NSMutableDictionary *commentParams = [NSMutableDictionary dictionary];
    
    [commentParams setObject:comment.content forKey:@"content"];
    [commentParams setObject:comment.parentID forKey:@"parent"];
    [commentParams setObject:comment.postID forKey:@"post_id"];
    [commentParams setObject:comment.status forKey:@"status"];
    
    return commentParams;
}

- (NSMutableArray *)wpGetCommentsForBlog:(Blog *)blog {
    XMLRPCRequest *xmlrpcRequest = [[XMLRPCRequest alloc] initWithHost:[NSURL URLWithString:blog.xmlrpc]];
    // TODO: use app-wide setting for number of posts
    NSDictionary *commentsStructure = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:100] forKey:@"number"];
    NSArray *args = [NSArray arrayWithObject:commentsStructure];
	[xmlrpcRequest setMethod:@"wp.getComments" withObjects:[self getXMLRPCArgsForBlog:blog withExtraArgs:args]];
    NSArray *recentComments = [self executeXMLRPCRequest:xmlrpcRequest];
	[xmlrpcRequest release];
    
    if ([recentComments isKindOfClass:[NSError class]]) {
        NSLog(@"Couldn't get recent comments: %@", [(NSError *)recentComments localizedDescription]);
        return [NSMutableArray array];
    }
    return [NSMutableArray arrayWithArray:recentComments];
}

- (NSNumber *)wpNewComment:(Comment *)comment {
    XMLRPCRequest *xmlrpcRequest = [[XMLRPCRequest alloc] initWithHost:[NSURL URLWithString:comment.blog.xmlrpc]];
    NSMutableDictionary *commentParams = [self getXMLRPCDictionaryForComment:comment];
    NSArray *args = [NSArray arrayWithObjects:comment.blog.blogID, comment.blog.username, [self passwordForBlog:comment.blog], comment.postID, commentParams, nil];
    
    [xmlrpcRequest setMethod:@"wp.newComment" withObjects:args];
    NSNumber *result = [self executeXMLRPCRequest:xmlrpcRequest];
    if ([result isKindOfClass:[NSError class]]) {
        NSLog(@"wpNewComment failed: %@", result);
        return nil;
    } else {
        return result;
    } 
}

- (BOOL)wpEditComment:(Comment *)comment {
    if (comment.commentID == nil) {
        return NO;
    }
    
    XMLRPCRequest *xmlrpcRequest = [[XMLRPCRequest alloc] initWithHost:[NSURL URLWithString:comment.blog.xmlrpc]];
    NSMutableDictionary *commentParams = [self getXMLRPCDictionaryForComment:comment];
    NSArray *args = [NSArray arrayWithObjects:comment.blog.blogID, comment.blog.username, [self passwordForBlog:comment.blog], comment.commentID, commentParams, nil];
    
    [xmlrpcRequest setMethod:@"wp.editComment" withObjects:args];
    id result = [self executeXMLRPCRequest:xmlrpcRequest];
    if ([result isKindOfClass:[NSError class]]) {
        NSLog(@"wpEditComment failed: %@", result);
        return NO;
    } else {
        return YES;
    }    
}

- (BOOL)wpDeleteComment:(Comment *)comment {
    if (comment.commentID == nil)
        return YES;
    
    XMLRPCRequest *xmlrpcRequest = [[XMLRPCRequest alloc] initWithHost:[NSURL URLWithString:comment.blog.xmlrpc]];
    NSArray *args = [NSArray arrayWithObjects:comment.blog.blogID, comment.blog.username, [self passwordForBlog:comment.blog], comment.commentID, nil];
    
    [xmlrpcRequest setMethod:@"wp.deleteComment" withObjects:args];
    id result = [self executeXMLRPCRequest:xmlrpcRequest];
    if ([result isKindOfClass:[NSError class]]) {
        NSLog(@"wpDeleteComment failed: %@", result);
        return NO;
    } else {
        return YES;
    }    
}

#pragma mark -
#pragma mark XMLRPC

- (NSArray *)getXMLRPCArgsForBlog:(Blog *)blog  withExtraArgs:(NSArray *)args {
    int size = 3;
    if (args != nil) {
        size += [args count];
    }
    
    NSMutableArray *result = [NSMutableArray arrayWithCapacity:size];
    [result addObject:blog.blogID];
    [result addObject:blog.username];
    [result addObject:[self passwordForBlog:blog]];
    [result addObjectsFromArray:args];
    
    return [NSArray arrayWithArray:result];
}

- (id)executeXMLRPCRequest:(XMLRPCRequest *)req {
	ASIHTTPRequest *request = [[ASIHTTPRequest alloc] initWithURL:[req host]];
	[request setRequestMethod:@"POST"];
	[request setShouldPresentCredentialsBeforeChallenge:YES];
	[request setShouldPresentAuthenticationDialog:YES];
	[request setUseKeychainPersistence:YES];
    [request setValidatesSecureCertificate:NO];
    [request appendPostData:[[req source] dataUsingEncoding:NSUTF8StringEncoding]];
	[request startSynchronous];

	XMLRPCResponse *userInfoResponse = [[[XMLRPCResponse alloc] initWithData:[request responseData]] autorelease];
	
	NSError *error = [request error];
    if (error) {
        NSLog(@"executeXMLRPCRequest error: %@", error);
        return error;
    }
	
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
