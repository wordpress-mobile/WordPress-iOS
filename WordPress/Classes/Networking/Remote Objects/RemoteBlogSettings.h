#import <Foundation/Foundation.h>

@interface RemoteBlogSettings : NSObject

// General
@property (copy) NSString *ID;
@property (copy) NSString *name;
@property (copy) NSString *desc;
@property (copy) NSNumber *blogPublic;
@property (copy) NSString *language;
@property (assign) BOOL relatedPosts;
@property (assign) BOOL relatedPostsShowHeadline;
@property (assign) BOOL relatedPostsShowThumbnails;

@end
