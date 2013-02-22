//
//  JetpackAuthUtil.m
//  WordPress
//
//  Created by Eric Johnson on 8/22/12.
//  Copyright (c) 2012 WordPress. All rights reserved.
//

#import "JetpackAuthUtil.h"
#import "Blog+Jetpack.h"
#import "SFHFKeychainUtils.h"
#import "AFHTTPClient.h"
#import "AFXMLRequestOperation.h"

@interface JetpackAuthUtil() <NSXMLParserDelegate> {
    NSMutableString *currentNode;
    NSMutableDictionary *parsedBlog;
    Blog *blog;
    NSString *username;
    NSString *password;
    BOOL foundMatchingBlogInAPI;
    AFXMLRequestOperation *currentRequest;
}

@property (nonatomic, strong) Blog *blog;
@property (nonatomic, strong) NSMutableString *currentNode;
@property (nonatomic, strong) NSMutableDictionary *parsedBlog;
@property (nonatomic, strong) NSString *username;
@property (nonatomic, strong) NSString *password;
@property (nonatomic, strong) AFXMLRequestOperation *currentRequest;

- (void)saveCredentials;

@end


@implementation JetpackAuthUtil

@synthesize delegate;
@synthesize currentNode;
@synthesize parsedBlog;
@synthesize blog;
@synthesize username;
@synthesize password;
@synthesize currentRequest;

+ (NSString *)getWporgBlogJetpackKey:(NSString *)urlPath {
	return [NSString stringWithFormat:@"jetpackblog-%@", urlPath];
}


+ (NSString *)getJetpackUsernameForBlog:(Blog *)blog {
	return [[NSUserDefaults standardUserDefaults] objectForKey:[self getWporgBlogJetpackKey:blog.url]];
}


+ (NSString *)getJetpackPasswordForBlog:(Blog *)blog {
    NSError *error = nil;
    return [SFHFKeychainUtils getPasswordForUsername:[self getJetpackUsernameForBlog:blog] andServiceName:@"WordPress.com" error:&error];
}


+ (void)setCredentialsForBlog:(Blog *)blog withUsername:(NSString *)username andPassword:(NSString *)password {
    if (![blog isWPcom]) {
        if (username == nil) {
            NSString *oldusername = [self getJetpackUsernameForBlog:blog];
            if (oldusername) {
                NSError *error = nil;
                [SFHFKeychainUtils deleteItemForUsername:oldusername andServiceName:@"WordPress.com" error:&error];
            }
            [[NSUserDefaults standardUserDefaults] removeObjectForKey:[[self class] getWporgBlogJetpackKey:blog.url]];
            [NSUserDefaults resetStandardUserDefaults];
            
        } else {
            [[NSUserDefaults standardUserDefaults] setObject:username forKey:[[self class] getWporgBlogJetpackKey:blog.url]];
            [NSUserDefaults resetStandardUserDefaults];
            NSError *error = nil;
            [SFHFKeychainUtils storeUsername:username andPassword:password forServiceName:@"WordPress.com" updateExisting:YES error:&error];
        }
    }
}


- (void)dealloc {
    
    if ([currentRequest isExecuting]) {
        [currentRequest cancel];
    }
    
}


- (void)validateCredentialsForBlog:(Blog *)aBlog withUsername:(NSString *)aUsername andPassword:(NSString *)aPassword {
    if ([aBlog isWPcom]) {
        [self.delegate jetpackAuthUtil:self invalidBlog:blog];
        return;
    }
    
    if (currentRequest) return;
    
    [FileLogger log:@"%@ %@", self, NSStringFromSelector(_cmd)];    
    foundMatchingBlogInAPI = NO;
    self.blog = aBlog;
    self.username = aUsername;
    self.password = aPassword;

    NSURL *baseURL = [NSURL URLWithString:@"https://public-api.wordpress.com/"];
    
    AFHTTPClient *httpClient = [[AFHTTPClient alloc] initWithBaseURL:baseURL];
    [httpClient setAuthorizationHeaderWithUsername:username password:password];
    
    NSMutableURLRequest *mRequest = [httpClient requestWithMethod:@"GET" path:@"get-user-blogs/1.0" parameters:nil];
    
    self.currentRequest = [[AFXMLRequestOperation alloc] initWithRequest:mRequest];
    
    __weak JetpackAuthUtil *jetpackAuthUtil = self;
    [currentRequest setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        jetpackAuthUtil.currentRequest = nil;
        if (jetpackAuthUtil) {
            NSXMLParser *parser = (NSXMLParser *)responseObject;
            parser.delegate = jetpackAuthUtil;
            [parser parse];
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        WPLog(@"Error calling get-user-blogs : %@", [error description]);
        jetpackAuthUtil.currentRequest = nil;
        
        if(operation.response.statusCode == 401){
            // If we failed due to bad credentials...
            [jetpackAuthUtil.delegate jetpackAuthUtil:jetpackAuthUtil errorValidatingCredentials:jetpackAuthUtil.blog withError:NSLocalizedString(@"The WordPress.com username or password may be incorrect. Please check them and try again.", @"")];
        } else {
            // Some other server error.
            [jetpackAuthUtil.delegate jetpackAuthUtil:jetpackAuthUtil errorValidatingCredentials:jetpackAuthUtil.blog withError:NSLocalizedString(@"There was a server error while testing the credentials. Please try again.", @"")];
        }        
    }];
    
    [currentRequest start];
}


- (void)saveCredentials {
    [[self class] setCredentialsForBlog:blog withUsername:username andPassword:password];
}


#pragma mark -
#pragma mark XMLParser Delegate Methods

- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary *)attributeDict {
	self.currentNode = [NSMutableString string];
    if([elementName isEqualToString:@"blog"]) {
        self.parsedBlog = [NSMutableDictionary dictionary];
    }
}


- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string {
	if (self.currentNode) {
        [self.currentNode appendString:string];
    }	
}


- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName {
    
    if ([elementName isEqualToString:@"apikey"]) {
        [blog setValue:currentNode forKey:@"apiKey"];
        [blog dataSave];
        
    } else if([elementName isEqualToString:@"blog"]) {
        NSURL *parsedURL = [NSURL URLWithString:[parsedBlog objectForKey:@"url"]];
        NSURL *blogURL = [NSURL URLWithString:blog.url];
        [FileLogger log:@"Blog URL - %@", blogURL];
        [FileLogger log:@"Parsed URL - %@", parsedURL];
        
        //Try to match the Jetpack ID. The WordPress.com ID of the Jetpack blog was introduced in options in Jetpack 1.8.2 or higher
        if ( [blog getOptionValue:@"jetpack_client_id"] ) {
            NSNumber *jetpackClientID = [blog jetpackBlogID];
            NSNumber *blogID = [[parsedBlog objectForKey:@"id"] numericValue];

            if ([jetpackClientID isEqualToNumber:blogID]) {
                // Mark that a match was found but continue.
                // http://ios.trac.wordpress.org/ticket/1251
                foundMatchingBlogInAPI = YES;
                NSLog(@"Matched parsedBlogURL: %@ to blogURL: %@ ", parsedURL, blogURL);
                NSLog(@"Matched parsedBlogID: %@", [blogID stringValue]);
            }
        }
        self.parsedBlog = nil;
        
    } else if([elementName isEqualToString:@"id"]) {
        [parsedBlog setValue:currentNode forKey:@"id"];
        [FileLogger log:@"Blog id - %@", currentNode];
    } else if([elementName isEqualToString:@"url"]) {
        [parsedBlog setValue:currentNode forKey:@"url"];
        [FileLogger log:@"Blog original URL - %@", currentNode];
    } else if([elementName isEqualToString:@"userinfo"]) {
        // Reached the end of the document.
    }
    
	self.currentNode = nil;
}


- (void)parser:(NSXMLParser *)parser parseErrorOccurred:(NSError *)parseError {
    self.currentNode = nil;
    self.parsedBlog = nil;
    
    // Error parsing API result.
    [self.delegate jetpackAuthUtil:self errorValidatingCredentials:blog withError:NSLocalizedString(@"The server responded with an unexpected result.",@"")];
}


- (void)parserDidEndDocument:(NSXMLParser *)parser {
    self.currentNode = nil;
    self.parsedBlog = nil;
    
    if (foundMatchingBlogInAPI) {
        [self saveCredentials];
        [self.delegate jetpackAuthUtil:self didValidateCredentailsForBlog:blog];
        
    } else {
        // Couldn't find blog. not hooked up or wrong .com account.
        [self.delegate jetpackAuthUtil:self noRecordForBlog:blog];
    }
}

@end
