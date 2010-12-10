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
		CXMLDocument *xml = [[[CXMLDocument alloc] initWithXMLString:[request responseString] options:0 error:nil] autorelease];
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
			for(NSDictionary *dictBlog in usersBlogsData) {
				Blog *blog = [[Blog alloc] init];
				if((int)[dictBlog valueForKey:@"isAdmin"] == 1)
					blog.isAdmin = [[dictBlog valueForKey:@"isAdmin"] boolValue];
				
				[blog setUsername:username];
				[blog setPassword:password];
				
				if([[dictBlog objectForKey:@"blogid"] isKindOfClass:[NSString class]])
					[blog setBlogID:[dictBlog objectForKey:@"blogid"]];
				else
					[blog setBlogID:[[dictBlog objectForKey:@"blogid"] stringValue]];
				NSString *blogName = [NSString decodeXMLCharactersIn:[dictBlog valueForKey:@"blogName"]];
				
				if([blogName isEqualToString:@""] == YES)
					[blog setBlogName:[dictBlog valueForKey:@"url"]]; 
				else
					[blog setBlogName:blogName];
				
				[blog setUrl:[dictBlog valueForKey:@"url"]];
				
				NSRange textRange = [blog.url.lowercaseString rangeOfString:@"wordpress.com"];
				NSString *hostURL = [[NSString alloc] initWithFormat:@"%@", 
									 [blog.url stringByReplacingOccurrencesOfRegex:@"http(s?)://" withString:@""]];
				if(textRange.location != NSNotFound)
				{
					hostURL = [NSString stringWithFormat:@"%@_%@", blog.username, 
										 [blog.url stringByReplacingOccurrencesOfRegex:@"http(s?)://" withString:@""]];
				}
								   
			   if([hostURL hasSuffix:@"/"])
				   hostURL = [hostURL substringToIndex:[hostURL length] - 1];
								   
			   [blog setHostURL:hostURL];
			   [blog setXmlrpc:[dictBlog valueForKey:@"xmlrpc"]];
			   [usersBlogs addObject:blog];
			}
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
