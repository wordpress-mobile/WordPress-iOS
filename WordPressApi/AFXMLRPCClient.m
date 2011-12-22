//
//  AFXMLRPCClient.m
//  WordPressApiExample
//
//  Created by Jorge Bernal on 12/13/11.
//  Copyright (c) 2011 Automattic. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AFXMLRPCClient.h"
#import "AFHTTPRequestOperation.h"
#import "XMLRPCEncoder.h"
#import "XMLRPCResponse.h"

static NSUInteger const kAFXMLRPCClientDefaultMaxConcurrentOperationCount = 4;

@interface AFXMLRPCClient ()
@property (readwrite, nonatomic, retain) NSURL *xmlrpcEndpoint;
@property (readwrite, nonatomic, retain) NSMutableDictionary *defaultHeaders;
@property (readwrite, nonatomic, retain) NSOperationQueue *operationQueue;
@end

@implementation AFXMLRPCClient {
    NSURL *_xmlrpcEndpoint;
    NSMutableDictionary *_defaultHeaders;
    NSOperationQueue *_operationQueue;
}
@synthesize xmlrpcEndpoint = _xmlrpcEndpoint;
@synthesize defaultHeaders = _defaultHeaders;
@synthesize operationQueue = _operationQueue;

#pragma mark - Creating and Initializing XML-RPC Clients

+ (AFXMLRPCClient *)clientWithXMLRPCEndpoint:(NSURL *)xmlrpcEndpoint {
    return [[[self alloc] initWithXMLRPCEndpoint:xmlrpcEndpoint] autorelease];
}

- (id)initWithXMLRPCEndpoint:(NSURL *)xmlrpcEndpoint {
    self = [super init];
    if (!self) {
        return nil;
    }
    
    self.xmlrpcEndpoint = xmlrpcEndpoint;
    
    self.defaultHeaders = [NSMutableDictionary dictionary];
    
	// Accept-Encoding HTTP Header; see http://www.w3.org/Protocols/rfc2616/rfc2616-sec14.html#sec14.3
	[self setDefaultHeader:@"Accept-Encoding" value:@"gzip"];
    
    NSString *applicationUserAgent = [[NSUserDefaults standardUserDefaults] objectForKey:@"UserAgent"];
    if (applicationUserAgent) {
        [self setDefaultHeader:@"User-Agent" value:applicationUserAgent];
    } else {
        [self setDefaultHeader:@"User-Agent" value:[NSString stringWithFormat:@"%@/%@ (%@, %@ %@, %@, Scale/%f)", [[[NSBundle mainBundle] infoDictionary] objectForKey:(NSString *)kCFBundleIdentifierKey], [[[NSBundle mainBundle] infoDictionary] objectForKey:(NSString *)kCFBundleVersionKey], @"unknown", [[UIDevice currentDevice] systemName], [[UIDevice currentDevice] systemVersion], [[UIDevice currentDevice] model], ([[UIScreen mainScreen] respondsToSelector:@selector(scale)] ? [[UIScreen mainScreen] scale] : 1.0)]];
    }
    
    self.operationQueue = [[[NSOperationQueue alloc] init] autorelease];
	[self.operationQueue setMaxConcurrentOperationCount:kAFXMLRPCClientDefaultMaxConcurrentOperationCount];

    return self;
}

- (void)dealloc {
    [_xmlrpcEndpoint release];
    [_defaultHeaders release];
    [_operationQueue release];
    [super dealloc];
}

#pragma mark - Managing HTTP Header Values

- (NSString *)defaultValueForHeader:(NSString *)header {
	return [self.defaultHeaders valueForKey:header];
}

- (void)setDefaultHeader:(NSString *)header value:(NSString *)value {
	[self.defaultHeaders setValue:value forKey:header];
}

- (void)setAuthorizationHeaderWithUsername:(NSString *)username password:(NSString *)password {
    // TODO: not implemented yet
//	NSString *basicAuthCredentials = [NSString stringWithFormat:@"%@:%@", username, password];
//    [self setDefaultHeader:@"Authorization" value:[NSString stringWithFormat:@"Basic %@", AFBase64EncodedStringFromString(basicAuthCredentials)]];
}

- (void)setAuthorizationHeaderWithToken:(NSString *)token {
    [self setDefaultHeader:@"Authorization" value:[NSString stringWithFormat:@"Token token=\"%@\"", token]];
}

- (void)clearAuthorizationHeader {
	[self.defaultHeaders removeObjectForKey:@"Authorization"];
}

#pragma mark - Creating Request Objects

- (NSMutableURLRequest *)requestWithMethod:(NSString *)method
                                parameters:(NSArray *)parameters {
    NSMutableURLRequest *request = [[[NSMutableURLRequest alloc] initWithURL:self.xmlrpcEndpoint] autorelease];
    [request setHTTPMethod:@"POST"];
    [request setAllHTTPHeaderFields:self.defaultHeaders];
    
    XMLRPCEncoder *encoder = [[XMLRPCEncoder alloc] init];
    [encoder setMethod:method withParameters:parameters];
    NSData *content = [[encoder encode] dataUsingEncoding: NSUTF8StringEncoding];
    [request setHTTPBody:content];
    
    return request;
}

#pragma mark - Creating HTTP Operations

- (AFHTTPRequestOperation *)HTTPRequestOperationWithRequest:(NSURLRequest *)request 
                                                    success:(void (^)(AFHTTPRequestOperation *operation, id responseObject))success
                                                    failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure {
    AFHTTPRequestOperation *operation = [[[AFHTTPRequestOperation alloc] initWithRequest:request] autorelease];
    

    void (^xmlrpcSuccess)(AFHTTPRequestOperation *, id) = ^(AFHTTPRequestOperation *operation, id responseObject) {
        XMLRPCResponse *response = [[XMLRPCResponse alloc] initWithData:responseObject];
        NSError *err = nil;
        
        if ([response isFault]) {
            NSDictionary *usrInfo = [NSDictionary dictionaryWithObjectsAndKeys:[response faultString], NSLocalizedDescriptionKey, nil];
            err = [NSError errorWithDomain:@"XMLRPC" code:[[response faultCode] intValue] userInfo:usrInfo];
        }
        
        if (err) {
            if (failure) {
                failure(operation, err);
            }
        } else {
            if (success) {
                success(operation, [response object]);
            }
        }
    };
    [operation setCompletionBlockWithSuccess:xmlrpcSuccess failure:failure];
    
    return operation;
}


#pragma mark - Managing Enqueued HTTP Operations

- (void)enqueueHTTPRequestOperation:(AFHTTPRequestOperation *)operation {
    [self.operationQueue addOperation:operation];
}

- (void)cancelAllHTTPOperations {
    for (AFHTTPRequestOperation *operation in [self.operationQueue operations]) {
        [operation cancel];
    }
}

#pragma mark - Making XML-RPC Requests

- (void)callMethod:(NSString *)method
        parameters:(NSArray *)parameters
           success:(void (^)(AFHTTPRequestOperation *operation, id responseObject))success
           failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure {
    NSURLRequest *request = [self requestWithMethod:method parameters:parameters];
    AFHTTPRequestOperation *operation = [self HTTPRequestOperationWithRequest:request success:success failure:failure];
    [self enqueueHTTPRequestOperation:operation];
}


@end
