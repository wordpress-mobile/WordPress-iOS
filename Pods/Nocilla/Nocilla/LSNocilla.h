#import <Foundation/Foundation.h>
#import "Nocilla.h"

@class LSStubRequest;

extern NSString * const LSUnexpectedRequest;

@interface LSNocilla : NSObject
+ (LSNocilla *)sharedInstance;

@property (nonatomic, strong, readonly) NSArray *stubbedRequests;
- (void)start;
- (void)stop;
- (void)addStubbedRequest:(LSStubRequest *)request;
- (void)clearStubs;
@end
