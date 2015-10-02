#import <Foundation/Foundation.h>

@interface RemoteBlogSettings : NSObject

// General
@property (copy) NSString *name;
@property (copy) NSString *desc;
@property (strong) NSNumber *privacy;

// Reading
@property (strong) NSNumber *relatedPostsAllowed;
@property (strong) NSNumber *relatedPostsEnabled;
@property (strong) NSNumber *relatedPostsShowHeadline;
@property (strong) NSNumber *relatedPostsShowThumbnails;

// Writing
@property (strong) NSNumber *defaultCategory;
@property (copy) NSString *defaultPostFormat;

@end
