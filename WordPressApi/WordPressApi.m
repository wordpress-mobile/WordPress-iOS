//
//  WordPressApi.m
//  WordPress
//
//  Created by Jorge Bernal on 1/5/12.
//  Copyright (c) 2012 WordPress. All rights reserved.
//

#import "WordPressApi.h"
#import "AFXMLRPCClient.h"

@interface WordPressApi ()
@property (readwrite, nonatomic, retain) NSURL *xmlrpc;
@property (readwrite, nonatomic, retain) NSString *username;
@property (readwrite, nonatomic, retain) NSString *password;
@property (readwrite, nonatomic, retain) AFXMLRPCClient *client;
@end


@implementation WordPressApi {
    NSURL *_xmlrpc;
    NSString *_username;
    NSString *_password;
    AFXMLRPCClient *_client;
}
@synthesize xmlrpc = _xmlrpc;
@synthesize username = _username;
@synthesize password = _password;
@synthesize client = _client;

+ (WordPressApi *)apiWithXMLRPCEndpoint:(NSURL *)xmlrpc username:(NSString *)username password:(NSString *)password {
    return [[[self alloc] initWithXMLRPCEndpoint:xmlrpc username:username password:password] autorelease];
}


- (id)initWithXMLRPCEndpoint:(NSURL *)xmlrpc username:(NSString *)username password:(NSString *)password
{
    self = [super init];
    if (!self) {
        return nil;
    }

    self.xmlrpc = xmlrpc;
    self.username = username;
    self.password = password;

    self.client = [AFXMLRPCClient clientWithXMLRPCEndpoint:xmlrpc];

    return self;
}

- (void)dealloc {
    [_xmlrpc release];
    [_username release];
    [_password release];
    [_client release];
    [super dealloc];
}

#pragma mark - Authentication

- (void)authenticateWithSuccess:(void (^)())success failure:(void (^)(NSError *error))failure {
    [self getBlogsWithSuccess:^(NSArray *blogs) {
        if (success) {
            success();
        }
    } failure:failure];
}

- (void)getBlogsWithSuccess:(void (^)(NSArray *blogs))success failure:(void (^)(NSError *error))failure {
    [self.client callMethod:@"wp.getUsersBlogs"
                 parameters:[NSArray arrayWithObjects:self.username, self.password, nil]
                    success:^(AFHTTPRequestOperation *operation, id responseObject) {
                        if (success) {
                            success(responseObject);
                        }
                    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                        if (failure) {
                            failure(error);
                        }
                    }];
}


#pragma mark - Helpers

+ (void)guessXMLRPCURLForSite:(NSString *)url
                      success:(void (^)(NSURL *xmlrpcURL))success
                      failure:(void (^)())failure {
    // TODO: port guessing code to AFXMLRPC
    NSURL *xmlrpcURL = [NSURL URLWithString:url];
    if (xmlrpcURL) {
        if (success)
            success(xmlrpcURL);
    } else {
        if (failure)
            failure();
    }
}

@end
