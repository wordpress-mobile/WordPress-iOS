#import <Foundation/Foundation.h>
#import <WPMediaPicker/WPMediaPicker.h>
#import "Media.h"

@class Blog;
@class AbstractPost;

@interface Media(WPMediaAsset)<WPMediaAsset>

@end

@interface MediaLibraryGroup: NSObject <WPMediaGroup>

- (instancetype)initWithBlog:(Blog *)blog;

-(id<NSObject>)registerChangeObserverBlock:(WPMediaChangesBlock)callback;

-(void)unregisterChangeObserver:(id<NSObject>)blockKey;

@property (nonatomic, assign) WPMediaType filter;

@end

@interface MediaLibraryPickerDataSource : NSObject <WPMediaCollectionDataSource>

- (instancetype)initWithBlog:(Blog *)blog;

- (instancetype)initWithPost:(AbstractPost *)post;

@end
