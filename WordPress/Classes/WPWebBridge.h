//
//  WPWebBridge.h
//  WordPress
//
//  Created by Beau Collins on 7/19/12.
//  Copyright (c) 2012 WordPress. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface WPWebBridge : NSObject

@property (nonatomic, weak) id delegate;

+ (WPWebBridge *)bridge;

- (BOOL)handlesRequest:(NSURLRequest *)request;
- (NSString *)hybridAuthToken;
+ (NSString *)hybridAuthToken;
- (void)executeBatchFromRequest:(NSURLRequest *)request;
- (NSMutableURLRequest *)authorizeHybridRequest:(NSMutableURLRequest *)request;
- (BOOL)requestIsValidHybridRequest:(NSURLRequest *)request;
+ (NSURL *)authorizeHybridURL:(NSURL *) url;
+ (BOOL)isValidHybridURL:(NSURL *)url;

@end
