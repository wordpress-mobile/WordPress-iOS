//
//  WordPressRestApiJSONRequestOperation.m
//  WordPressApiExample
//
//  Created by Jorge Bernal on 2/20/13.
//  Copyright (c) 2013 Automattic. All rights reserved.
//

#import "WordPressRestApiJSONRequestOperation.h"
#import "WordPressRestApi.h"

@implementation WordPressRestApiJSONRequestOperation

+(BOOL)canProcessRequest:(NSURLRequest *)urlRequest {
    NSURL *testURL = [NSURL URLWithString:WordPressRestApiEndpointURL];
    if ([urlRequest.URL.host isEqualToString:testURL.host] && [urlRequest.URL.path rangeOfString:testURL.path].location == 0)
        return YES;

    return NO;
}

- (NSError *)error {
    if (self.response.statusCode >= 400) {
        NSString *errorMessage = [self.responseJSON objectForKey:@"message"];
        NSUInteger errorCode = WordPressRestApiErrorJSON;
        if ([self.responseJSON objectForKey:@"error"] && errorMessage) {
            NSString *error = [self.responseJSON objectForKey:@"error"];
            if ([error isEqualToString:@"invalid_token"]) {
                errorCode = WordPressRestApiErrorInvalidToken;
            } else if ([error isEqualToString:@"authorization_required"]) {
                errorCode = WordPressRestApiErrorAuthorizationRequired;
            }
            return [NSError errorWithDomain:WordPressRestApiErrorDomain code:errorCode userInfo:@{NSLocalizedDescriptionKey: errorMessage, WordPressRestApiErrorCodeKey: error}];
        }
    }
    return [super error];
}

@end