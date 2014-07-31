#import <Foundation/Foundation.h>
#import "WPWebSnapshotter.h"

@interface WPWebSnapshotRequest : NSObject

@property (nonatomic) NSURLRequest *urlRequest;
@property (nonatomic) CGSize snapshotSize;
@property (nonatomic) NSString *didFinishJavascript;
@property (nonatomic, copy) WPWebSnapshotterSnapshotCompletionHandler callback;

+ (instancetype)snapshotRequestWithURLRequest:(NSURLRequest *)urlRequest
                                 snapshotSize:(CGSize)snapshotSize
                          didFinishJavascript:(NSString *)javascript
                            completionHandler:(WPWebSnapshotterSnapshotCompletionHandler)completionHandler;

@end
