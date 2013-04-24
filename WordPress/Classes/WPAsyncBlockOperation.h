//
//  WPAsyncOperation.h
//  WordPress
//
//  Created by Sendhil Panchadsaram on 4/16/13.
//  Copyright (c) 2013 WordPress. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface WPAsyncBlockOperation : NSOperation

@property (nonatomic, assign) BOOL failed;

+ (id)operationWithBlock:(void(^)(WPAsyncBlockOperation *))block;
- (void)addBlock:(void(^)(WPAsyncBlockOperation *))block;
- (void)didSucceed;
- (void)didFail;

@end
