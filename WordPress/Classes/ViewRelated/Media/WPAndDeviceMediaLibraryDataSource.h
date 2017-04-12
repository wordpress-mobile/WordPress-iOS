#import <Foundation/Foundation.h>
#import <WPMediaPicker/WPMediaPicker.h>

@class Blog;
@class AbstractPost;

typedef NS_ENUM(NSUInteger, MediaPickerDataSourceType) {
    MediaPickerDataSourceTypeMediaLibrary,
    MediaPickerDataSourceTypeDevice
};

@interface WPAndDeviceMediaLibraryDataSource : NSObject <WPMediaCollectionDataSource>

@property (nonatomic) MediaPickerDataSourceType dataSourceType;

- (instancetype)initWithBlog:(Blog *)blog;

- (instancetype)initWithPost:(AbstractPost *)post;

@end
