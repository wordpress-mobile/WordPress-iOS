#import <Foundation/Foundation.h>
#import <WPMediaPicker/WPMediaPicker.h>
#import "Media.h"

@class Blog;

@interface Media(WPMediaAsset)<WPMediaAsset>

@end

@interface MediaLibraryGroup: NSObject <WPMediaGroup>

- (instancetype)initWithBlog:(Blog *)blog NS_DESIGNATED_INITIALIZER;

@end

@interface MediaLibraryPickerDataSource : NSObject <WPMediaCollectionDataSource>

- (instancetype)initWithBlog:(Blog *)blog NS_DESIGNATED_INITIALIZER;

@end
