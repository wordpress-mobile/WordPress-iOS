#import <Foundation/Foundation.h>
#import <WPMediaPicker/WPMediaPicker.h>
#import "Media.h"
#import "Media+WPMediaAsset.h"

@class Blog;
@class AbstractPost;

@interface MediaLibraryGroup: NSObject <WPMediaGroup>

- (nonnull instancetype)initWithBlog:(Blog *_Nonnull)blog;

@property (nonatomic, assign) WPMediaType filter;

@end

@interface MediaLibraryPickerDataSource : NSObject <WPMediaCollectionDataSource>

- (nonnull instancetype)initWithBlog:(Blog *_Nonnull)blog;

- (nonnull instancetype)initWithPost:(AbstractPost *_Nonnull)post;

/// If a search query is set, the media assets fetched by the data source
/// will be filtered to only those whose name, caption, or description
/// contain the search query.
@property (nonatomic, copy, nullable) NSString *searchQuery;

/// Defaults to `NO`.
/// By default, the data source will only show media that has been synced to the
/// remote. Set this to `YES` to include local-only media, or media that is
/// currently being processed or uploaded.
@property (nonatomic) BOOL includeUnsyncedMedia;

/// Defaults to `NO`.
/// By default, errors (causes by e.g. devices being offline, or user using a slow network) when syncing
/// will cause `-[WPMediaCollectionDataSource loadDataWithOptions:success:failure:]` to call the
/// failure block. Setting this to `YES` will override this behavior, and will call the `successBlock` instead.
/// Note: this only applies to the fetching operation — write/upload operations will still return errors as
/// normal.
@property (nonatomic) BOOL ignoreSyncErrors;

/// The total asset account, ignoring the current search query if there is one.
@property (nonatomic, readonly) NSInteger totalAssetCount;

@end
