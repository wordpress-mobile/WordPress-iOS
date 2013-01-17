//
//  WordPressComRestClient.m
//  Subclass of AFHTTPClient that conveniently sets:
//   - the baseURL
//   - the Authorization header
//   - the User-Agent headers
//
//  Created by Beau Collins on 11/05/12.
//  Copyright (c) 2012 WordPress. All rights reserved.
//

#import "WordPressComRestClient.h"
#import "WordPressAppDelegate.h"
#import "AFJSONRequestOperation.h"

NSString *const WordPressComRestClientEndpointURL = @"https://public-api.wordpress.com/rest/v1/";

@interface WordPressComRestClient ()
@property (getter = isAuthorized, readwrite) BOOL authorized;

@end


// AFJSONRequestOperation requires that a URI end with .json in order to match
// This will match all public-api.wordpress.com/rest/v1/ URI's and parse them as JSON
@interface WPJSONRequestOperation : AFJSONRequestOperation

@end

@implementation WPJSONRequestOperation

+(BOOL)canProcessRequest:(NSURLRequest *)urlRequest {    
    return [[urlRequest.URL host] isEqualToString:@"public-api.wordpress.com"] && [urlRequest.URL.path rangeOfString:@"/rest/v1/"].location == 0;
}

@end

@implementation WordPressComRestClient


- (id)initWithBaseURL:(NSURL *)url {
    if (self = [super initWithBaseURL:url]) {
        WordPressAppDelegate *appDelegate = (WordPressAppDelegate *)[UIApplication sharedApplication].delegate;
        [self setDefaultHeader:@"User-Agent" value:appDelegate.applicationUserAgent];
        [self registerHTTPOperationClass:[WPJSONRequestOperation class]];
    }
    return self;
}

- (void)dealloc {
    self.authToken = nil;
    self.delegate = nil;
}

- (void)setAuthToken:(NSString *)authToken {
    if (_authToken != authToken) {
        _authToken = authToken;
    }
    [self setDefaultHeader:@"Authorization" value:[NSString stringWithFormat:@"Bearer %@", authToken ] ];
    self.authorized = YES;
}

- (AFHTTPRequestOperation *)HTTPRequestOperationWithRequest:(NSURLRequest *)urlRequest success:(void (^)(AFHTTPRequestOperation *, id))success failure:(void (^)(AFHTTPRequestOperation *, NSError *))failure {
    // wrap each failure with our own failure to detect a 403
    return [super HTTPRequestOperationWithRequest:urlRequest success:success failure:^(AFHTTPRequestOperation *operation, NSError *error){
        NSHTTPURLResponse *response = [error.userInfo objectForKey:AFNetworkingOperationFailingURLResponseErrorKey];
        if( response.statusCode == 403 || response.statusCode == 400 ){
            if ([self.delegate respondsToSelector:@selector(restClientDidFailAuthorization:)]){
                [self.delegate restClientDidFailAuthorization:self];
            }
        }
        if(failure != nil ) failure(operation, error);
    }];
    
}


@end
