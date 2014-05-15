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
