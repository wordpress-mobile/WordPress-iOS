#import <Foundation/Foundation.h>

@interface WPAsyncBlockOperation : NSOperation

@property (nonatomic, assign) BOOL failed;

+ (id)operationWithBlock:(void(^)(WPAsyncBlockOperation *))block;
- (void)addBlock:(void(^)(WPAsyncBlockOperation *))block;
- (void)didSucceed;
- (void)didFail;

@end
