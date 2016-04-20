#import <Foundation/Foundation.h>
#import <WPMediaPicker/WPMediaPicker.h>

@class Blog;
@class AbstractPost;

@interface WPAndDeviceMediaLibraryDataSource : NSObject <WPMediaCollectionDataSource>

- (instancetype)initWithBlog:(Blog *)blog;

- (instancetype)initWithPost:(AbstractPost *)post;

@end
