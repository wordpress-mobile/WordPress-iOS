@interface RemoteBlog : NSObject
@property (nonatomic,   copy) NSNumber  *blogID;
@property (nonatomic,   copy) NSString  *name;
@property (nonatomic,   copy) NSString  *tagline;
@property (nonatomic,   copy) NSString  *url;
@property (nonatomic,   copy) NSString  *xmlrpc;
@property (nonatomic,   copy) NSString  *icon;
@property (nonatomic, assign) BOOL      jetpack;
@property (nonatomic, assign) BOOL      isAdmin;
@property (nonatomic, assign) BOOL      visible;
@end
