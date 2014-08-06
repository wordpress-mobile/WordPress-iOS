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
    [operation addBlock:block];
    return operation;
}

- (BOOL)isConcurrent
{
    return YES;
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
        [self didFail];
        [self completeOperation];
        return;
    }

    [self willChangeValueForKey:@"isExecuting"];
    _executing = YES;
    [self didChangeValueForKey:@"isExecuting"];

    dispatch_async(dispatch_get_main_queue(), ^{
        self.executionBlock(self);
    });
}

- (void)didSucceed
{
    [self completeOperation];
}

- (void)didFail
{
    [self willChangeValueForKey:@"failed"];
    _failed = YES;
    [self didChangeValueForKey:@"failed"];
    [self completeOperation];
}

#pragma mark - Private Methods

- (void)completeOperation
{
    [self willChangeValueForKey:@"isFinished"];
    [self willChangeValueForKey:@"isExecuting"];

    _executing = NO;
    _finished = YES;

    [self didChangeValueForKey:@"isFinished"];
    [self didChangeValueForKey:@"isExecuting"];
}

- (BOOL)haveAnyDependenciesFailed
{
    for (NSOperation *operation in self.dependencies) {
        if ([operation isKindOfClass:[WPAsyncBlockOperation class]]) {
            WPAsyncBlockOperation *asyncBlockOperation = (WPAsyncBlockOperation *)operation;
            if (asyncBlockOperation.failed) {
                return YES;
            }
        }
    }

    return NO;
}

@end
