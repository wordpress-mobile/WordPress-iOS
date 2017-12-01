#import <Foundation/Foundation.h>
#import <WPMediaPicker/WPMediaPicker.h>

@class Blog;
@class AbstractPost;

typedef NS_ENUM(NSUInteger, MediaPickerDataSourceType) {
    MediaPickerDataSourceTypeDevice,
    MediaPickerDataSourceTypeMediaLibrary
};

@interface WPAndDeviceMediaLibraryDataSource : NSObject <WPMediaCollectionDataSource>

@property (nonatomic) MediaPickerDataSourceType dataSourceType;
@property (nonatomic, readonly, copy) NSString *searchQuery;

- (instancetype)initWithBlog:(Blog *)blog;
- (instancetype)initWithBlog:(Blog *)blog
       initialDataSourceType:(MediaPickerDataSourceType)sourceType;

- (instancetype)initWithPost:(AbstractPost *)post;
- (instancetype)initWithPost:(AbstractPost *)post
       initialDataSourceType:(MediaPickerDataSourceType)sourceType;

@end
