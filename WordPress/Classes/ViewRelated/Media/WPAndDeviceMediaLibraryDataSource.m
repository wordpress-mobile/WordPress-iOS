#import "WPAndDeviceMediaLibraryDataSource.h"
#import "MediaLibraryPickerDataSource.h"
#import "Blog.h"
#import "Post.h"

@interface WPAndDeviceMediaLibraryDataSource()
    @property (nonatomic, strong) MediaLibraryPickerDataSource *mediaLibraryDataSource;
    @property (nonatomic, strong) WPPHAssetDataSource *deviceLibraryDataSource;
    @property (nonatomic, strong) id<WPMediaCollectionDataSource> currentDataSource;
    @property (nonatomic, strong) NSMutableDictionary *observers;
@end

@implementation WPAndDeviceMediaLibraryDataSource

- (instancetype)initWithBlog:(Blog *)blog
{
    self = [super init];
    if (self) {
        _mediaLibraryDataSource = [[MediaLibraryPickerDataSource alloc] initWithBlog:blog];
        _deviceLibraryDataSource = [[WPPHAssetDataSource alloc] init];
        _currentDataSource = _deviceLibraryDataSource;
        _observers = [[NSMutableDictionary alloc] init];
    }
    return self;
}

- (instancetype)initWithPost:(AbstractPost *)post
{
    self = [super init];
    if (self) {
        _mediaLibraryDataSource = [[MediaLibraryPickerDataSource alloc] initWithPost:post];
        _deviceLibraryDataSource = [[WPPHAssetDataSource alloc] init];
        _currentDataSource = _deviceLibraryDataSource;
        _observers = [[NSMutableDictionary alloc] init];
    }
    return self;
}

- (NSInteger)numberOfGroups
{
    return [self.mediaLibraryDataSource numberOfGroups] + [self.deviceLibraryDataSource numberOfGroups];
}

- (id<WPMediaGroup>)groupAtIndex:(NSInteger)index
{
    NSInteger numberOfGroupsInMediaLibrary = [self.mediaLibraryDataSource numberOfGroups];
    if (index < numberOfGroupsInMediaLibrary) {
        return [self.mediaLibraryDataSource groupAtIndex:index];
    } else {
        return [self.deviceLibraryDataSource groupAtIndex:index - numberOfGroupsInMediaLibrary];
    }
    return nil;
}

- (id<WPMediaGroup>)selectedGroup
{
    return [self.currentDataSource selectedGroup];
}

- (void)setSelectedGroup:(id<WPMediaGroup>)group
{
    if ([group isKindOfClass:[MediaLibraryGroup class]]) {
        [self.mediaLibraryDataSource setSelectedGroup:group];
        self.currentDataSource = self.mediaLibraryDataSource;
    } else {
        [self.deviceLibraryDataSource setSelectedGroup:group];
        self.currentDataSource = self.deviceLibraryDataSource;
    }
}

- (NSInteger)numberOfAssets
{
    return [self.currentDataSource numberOfAssets];
}

- (id<WPMediaAsset>)mediaAtIndex:(NSInteger)index
{
    return [self.currentDataSource mediaAtIndex:index];
}

- (id<WPMediaAsset>)mediaWithIdentifier:(NSString *)identifier
{
    if (!identifier) {
        return nil;
    }
    id<WPMediaAsset> result = [self.deviceLibraryDataSource mediaWithIdentifier:identifier];
    if (result) {
        return result;
    }
    result = [self.mediaLibraryDataSource mediaWithIdentifier:identifier];
    return result;
}

- (id<NSObject>)registerChangeObserverBlock:(WPMediaChangesBlock)callback
{
    NSUUID *blockKey = [NSUUID UUID];
    __weak __typeof__(self) weakSelf = self;
    id<NSObject> oneKey = [self.deviceLibraryDataSource registerChangeObserverBlock:^(BOOL incrementalChanges, NSIndexSet *removed, NSIndexSet *inserted, NSIndexSet *changed, NSArray<id<WPMediaMove>> *moved) {
        if (weakSelf.currentDataSource == weakSelf.deviceLibraryDataSource) {
            if (callback) {
                callback(incrementalChanges, removed, inserted, changed, moved);
            }
        }
    }];
    id<NSObject> secondKey = [self.mediaLibraryDataSource registerChangeObserverBlock:^(BOOL incrementalChanges, NSIndexSet *removed, NSIndexSet *inserted, NSIndexSet *changed, NSArray<id<WPMediaMove>> *moved) {
        if (callback) {
            callback(incrementalChanges, removed, inserted, changed, moved);
        }
    }];
    
    self.observers[blockKey] = @[oneKey, secondKey];
    return blockKey;
}

- (void)unregisterChangeObserver:(id<NSObject>)blockKey
{
    NSArray *keys = self.observers[blockKey];
    if (!keys) {
        return;
    }
    [self.deviceLibraryDataSource unregisterChangeObserver:keys[0]];
    [self.mediaLibraryDataSource unregisterChangeObserver:keys[1]];
}

- (void)loadDataWithSuccess:(WPMediaSuccessBlock)successBlock
                    failure:(WPMediaFailureBlock)failureBlock
{
    [self.currentDataSource loadDataWithSuccess:successBlock failure:failureBlock];
}

- (void)addImage:(UIImage *)image metadata:(NSDictionary *)metadata completionBlock:(WPMediaAddedBlock)completionBlock
{
    [self.currentDataSource addImage:image metadata:metadata completionBlock:completionBlock];
}

- (void)addVideoFromURL:(NSURL *)url  completionBlock:(WPMediaAddedBlock)completionBlock
{
    [self.currentDataSource addVideoFromURL:url completionBlock:completionBlock];
}

- (void)setMediaTypeFilter:(WPMediaType)filter
{
    [self.mediaLibraryDataSource setMediaTypeFilter:filter];
    [self.deviceLibraryDataSource setMediaTypeFilter:filter];
}

- (WPMediaType)mediaTypeFilter
{
    return [self.currentDataSource mediaTypeFilter];
}

- (void)setAscendingOrdering:(BOOL)ascending
{
    [self.mediaLibraryDataSource setAscendingOrdering:ascending];
    [self.deviceLibraryDataSource setAscendingOrdering:ascending];
}

- (BOOL)ascendingOrdering
{
    return [self.currentDataSource ascendingOrdering];
}





@end
