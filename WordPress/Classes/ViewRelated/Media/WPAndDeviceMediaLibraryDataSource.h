#import <Foundation/Foundation.h>
#import <WPMediaPicker/WPMediaPicker.h>

@class Blog;
@class AbstractPost;

@interface WPAndDeviceMediaLibraryDataSource : NSObject <WPMediaCollectionDataSource>

- (instancetype)initWithBlog:(Blog *)blog NS_DESIGNATED_INITIALIZER;

- (instancetype)initWithPost:(AbstractPost *)post NS_DESIGNATED_INITIALIZER;

@end
