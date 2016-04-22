#import <AFNetworking/AFHTTPRequestOperation.h>

@class WPXMLRPCRequest;

@interface WPXMLRPCRequestOperation : NSObject
@property (nonatomic, strong) WPXMLRPCRequest *XMLRPCRequest;
@property (nonatomic, copy) void (^success)(AFHTTPRequestOperation *operation, id responseObject);
@property (nonatomic, copy) void (^failure)(AFHTTPRequestOperation *operation, NSError *error);
@end
