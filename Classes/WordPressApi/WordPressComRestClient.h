//
//  WordPressComRestClient.h
//  WordPress
//
//  Created by Beau Collins on 11/05/12.
//  Copyright (c) 2012 WordPress. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AFHTTPClient.h"

extern NSString *const WordPressComRestClientEndpointURL;

@protocol WordPressComRestClientDelegate;

@interface WordPressComRestClient : AFHTTPClient

@property (nonatomic, weak) id <WordPressComRestClientDelegate> delegate;
@property (nonatomic, strong) NSString *authToken;
@property (getter = isAuthorized, readonly) BOOL authorized;

@end

@protocol WordPressComRestClientDelegate <NSObject>

@optional

- (void)restClientDidFailAuthorization:(WordPressComRestClient *)client;

@end

