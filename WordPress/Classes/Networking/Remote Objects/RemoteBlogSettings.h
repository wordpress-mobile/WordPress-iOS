#import <Foundation/Foundation.h>

@interface RemoteBlogSettings : NSObject

// General
@property (copy) NSString *name;
@property (copy) NSString *desc;
@property (copy) NSNumber *privacy;

// Reading
@property (copy) NSNumber *relatedPostsAllowed;
@property (copy) NSNumber *relatedPostsEnabled;
@property (copy) NSNumber *relatedPostsShowHeadline;
@property (copy) NSNumber *relatedPostsShowThumbnails;

// Writing
@property (copy) NSNumber *defaultCategory;
@property (copy) NSString *defaultPostFormat;

@end
