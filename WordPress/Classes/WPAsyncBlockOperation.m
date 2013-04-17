//
//  WPAsyncOperation.m
//  WordPress
//
//  Created by Sendhil Panchadsaram on 4/16/13.
//  Copyright (c) 2013 WordPress. All rights reserved.
//

#import "WPAsyncBlockOperation.h"

typedef void (^ExecutionBlock)(WPAsyncBlockOperation *);

@interface WPAsyncBlockOperation() {
    BOOL _executing;
    BOOL _finished;
}

@property (nonatomic, copy) ExecutionBlock executionBlock;

@end

@implementation WPAsyncBlockOperation

- (id)init
{
    self = [super init];

    if (self) {
        _failed = NO;
        _executing = NO;
        _finished = NO;
    }
    
    return self;
}

+ (id)operationWithBlock:(void(^)(WPAsyncBlockOperation *))block;
{
    WPAsyncBlockOperation *operation = [[WPAsyncBlockOperation alloc] init];
    operation.executionBlock = block;
    return operation;
}

- (BOOL)isConcurrent
{
    return true;
}

- (BOOL)isExecuting
{
    return _executing;
}

- (BOOL)isFinished
{
    return _finished;
}

- (void)addBlock:(void(^)(WPAsyncBlockOperation *))block;
{
    self.executionBlock = block;
}

- (void)start
{
    if ([self isCancelled] || self.executionBlock == nil) {
        [self completeOperation];
        return;
    }
    
    if ([self haveAnyDependenciesFailed]) {
        [self operationFailed];
        [self completeOperation];
        return;
    }
    
    [self willChangeValueForKey:@"isExecuting"];
    _executing = YES;
    [self didChangeValueForKey:@"isExecuting"];

    self.executionBlock(self);
}

- (void)operationSucceeded
{
    [self completeOperation];
}

- (void)operationFailed
{
    [self willChangeValueForKey:@"failed"];
    _failed = true;
    [self didChangeValueForKey:@"failed"];
    
    [self completeOperation];
}

#pragma mark - Private Methods

- (void)completeOperation
{
    [self willChangeValueForKey:@"isFinished"];
    [self willChangeValueForKey:@"isExecuting"];
    
    _executing = false;
    _finished = true;
    
    [self didChangeValueForKey:@"isFinished"];
    [self didChangeValueForKey:@"isExecuting"];
}

- (BOOL)haveAnyDependenciesFailed
{
    for (NSOperation *operation in self.dependencies) {
        if ([operation isKindOfClass:[WPAsyncBlockOperation class]]) {
            WPAsyncBlockOperation *asyncBlockOperation = (WPAsyncBlockOperation *)operation;
            if (asyncBlockOperation.failed)
                return true;
        }
    }
    
    return false;
}

@end
