@interface RemoteBlog : NSObject
@property NSNumber *ID;
@property (copy) NSString *title;
@property (copy) NSString *desc;
@property (copy) NSString *url;
@property (copy) NSString *xmlrpc;
@property (assign) BOOL jetpack;
@property (copy) NSString *icon;
@property (assign) BOOL isAdmin;
@end