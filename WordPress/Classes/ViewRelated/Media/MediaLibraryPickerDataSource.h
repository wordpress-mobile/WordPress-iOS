#import <Foundation/Foundation.h>
#import <WPMediaPicker/WPMediaPicker.h>
#import "Media.h"

@class Blog;
@class AbstractPost;

@interface Media(WPMediaAsset)<WPMediaAsset>

@end

@interface MediaLibraryGroup: NSObject <WPMediaGroup>

- (instancetype)initWithBlog:(Blog *)blog NS_DESIGNATED_INITIALIZER;

@property (nonatomic, assign) WPMediaType filter;

@end

@interface MediaLibraryPickerDataSource : NSObject <WPMediaCollectionDataSource>

- (instancetype)initWithBlog:(Blog *)blog NS_DESIGNATED_INITIALIZER;

- (instancetype)initWithPost:(AbstractPost *)post;

@end
