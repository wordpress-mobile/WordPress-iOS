#import <Foundation/Foundation.h>
#import <WPMediaPicker/WPMediaPicker.h>
#import "Media.h"
#import "Media+WPMediaAsset.h"

@class Blog;
@class AbstractPost;

@interface MediaLibraryGroup: NSObject <WPMediaGroup>

- (instancetype)initWithBlog:(Blog *)blog;

-(id<NSObject>)registerChangeObserverBlock:(WPMediaChangesBlock)callback;

-(void)unregisterChangeObserver:(id<NSObject>)blockKey;

@property (nonatomic, assign) WPMediaType filter;

@end

@interface MediaLibraryPickerDataSource : NSObject <WPMediaCollectionDataSource>

- (instancetype)initWithBlog:(Blog *)blog;

- (instancetype)initWithPost:(AbstractPost *)post;

/// If a search query is set, the media assets fetched by the data source
/// will be filtered to only those whose name, caption, or description
/// contain the search query.
@property (nonatomic, copy) NSString *searchQuery;

/// Defaults to `NO`.
/// By default, the data source will only show media that has been synced to the
/// remote. Set this to `YES` to include local-only media, or media that is
/// currently being processed or uploaded.
@property (nonatomic) BOOL includeUnsyncedMedia;

/// The total asset account, ignoring the current search query if there is one.
@property (nonatomic, readonly) NSInteger totalAssetCount;

@end
