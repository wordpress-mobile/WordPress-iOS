@interface RemoteBlog : NSObject
@property NSNumber *ID;
@property (copy) NSString *title;
@property (copy) NSString *url;
@property (copy) NSString *xmlrpc;
@property (assign) BOOL jetpack;
@end