#import "WPWebSnapshotRequest.h"

@implementation WPWebSnapshotRequest

+ (instancetype)snapshotRequestWithURLRequest:(NSURLRequest *)urlRequest
                                 snapshotSize:(CGSize)snapshotSize
                          didFinishJavascript:(NSString *)javascript
                            completionHandler:(WPWebSnapshotterSnapshotCompletionHandler)completionHandler
{
    WPWebSnapshotRequest *request = [[WPWebSnapshotRequest alloc] init];
    request.urlRequest = urlRequest;
    request.snapshotSize = snapshotSize;
    request.didFinishJavascript = javascript;
    request.callback = completionHandler;
    
    return request;
}

@end
