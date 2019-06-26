#import "WPAndDeviceMediaLibraryDataSource.h"
#import "MediaLibraryPickerDataSource.h"
#import "Blog.h"

@interface WPAndDeviceMediaLibraryDataSource()
    @property (nonatomic, strong) MediaLibraryPickerDataSource *mediaLibraryDataSource;
    @property (nonatomic, strong) WPPHAssetDataSource *deviceLibraryDataSource;
    @property (nonatomic, strong) id<WPMediaCollectionDataSource> currentDataSource;
    @property (nonatomic, strong) NSMutableDictionary *observers;
    @property (nonatomic, strong) NSMutableDictionary *groupObservers;
    @property (nonatomic, readwrite, copy) NSString *searchQuery;
@end

@implementation WPAndDeviceMediaLibraryDataSource

- (instancetype)initWithBlog:(Blog *)blog
{
    return [self initWithBlog:blog
        initialDataSourceType:MediaPickerDataSourceTypeDevice];
}

- (instancetype)initWithBlog:(Blog *)blog
       initialDataSourceType:(MediaPickerDataSourceType)sourceType
{
    self = [super init];
    if (self) {
        _mediaLibraryDataSource = [[MediaLibraryPickerDataSource alloc] initWithBlog:blog];

        [self commonInitWithSourceType:sourceType];
    }
    return self;
}

- (instancetype)initWithPost:(AbstractPost *)post
{
    return [self initWithPost:post
        initialDataSourceType:MediaPickerDataSourceTypeDevice];
}

- (instancetype)initWithPost:(AbstractPost *)post
       initialDataSourceType:(MediaPickerDataSourceType)sourceType
{
    self = [super init];
    if (self) {
        _mediaLibraryDataSource = [[MediaLibraryPickerDataSource alloc] initWithPost:post];

        [self commonInitWithSourceType:sourceType];
    }
    return self;
}

- (void)commonInitWithSourceType:(MediaPickerDataSourceType)sourceType
{
    _deviceLibraryDataSource = [[WPPHAssetDataSource alloc] init];

    _observers = [[NSMutableDictionary alloc] init];
    _groupObservers = [[NSMutableDictionary alloc] init];
    _searchQuery = @"";
    _mediaLibraryDataSource.ignoreSyncErrors = YES;
    
    [self setDataSourceType:sourceType];
}

- (MediaPickerDataSourceType)dataSourceType
{
    return (_currentDataSource == _deviceLibraryDataSource) ? MediaPickerDataSourceTypeDevice : MediaPickerDataSourceTypeMediaLibrary;
}

- (void)setDataSourceType:(MediaPickerDataSourceType)dataSourceType
{
    switch (dataSourceType) {
        case MediaPickerDataSourceTypeDevice:
            _currentDataSource = _deviceLibraryDataSource;
            break;
        case MediaPickerDataSourceTypeMediaLibrary:
            _currentDataSource = _mediaLibraryDataSource;
        default:
            break;
    }
}

- (NSInteger)numberOfGroups
{
    return [self.mediaLibraryDataSource numberOfGroups] + [self.deviceLibraryDataSource numberOfGroups];
}

-(NSString *)searchQuery
{
    return self.mediaLibraryDataSource.searchQuery;
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

- (void)searchFor:(NSString *)searchText
{
    [self.mediaLibraryDataSource searchFor:searchText];
}

- (void)searchCancelled
{
    [self.mediaLibraryDataSource searchCancelled];
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
        if (weakSelf.currentDataSource == weakSelf.mediaLibraryDataSource) {
            if (callback) {
                callback(incrementalChanges, removed, inserted, changed, moved);
            }
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

-(id<NSObject>)registerGroupChangeObserverBlock:(WPMediaGroupChangesBlock)callback
{
    NSUUID *blockKey = [NSUUID UUID];
    id<NSObject> deviceKey = [self.deviceLibraryDataSource registerGroupChangeObserverBlock:callback];
    id<NSObject> mediaLibraryKey = [self.mediaLibraryDataSource registerGroupChangeObserverBlock:callback];
    self.groupObservers[blockKey] = @[deviceKey, mediaLibraryKey];
    return blockKey;
}

-(void)unregisterGroupChangeObserver:(id<NSObject>)blockKey
{
    NSArray *keys = self.groupObservers[blockKey];
    if (!keys) {
        return;
    }
    [self.deviceLibraryDataSource unregisterGroupChangeObserver:keys[0]];
    [self.mediaLibraryDataSource unregisterGroupChangeObserver:keys[1]];
}

- (void)loadDataWithOptions:(WPMediaLoadOptions)options
                    success:(WPMediaSuccessBlock)successBlock
                    failure:(WPMediaFailureBlock)failureBlock
{
    if (options == WPMediaLoadOptionsGroups || options == WPMediaLoadOptionsGroupsAndAssets) {
        [self.deviceLibraryDataSource loadDataWithOptions:options success:^{
            if (successBlock) {
                // the moment we have device data available show it
                successBlock();
            }
            [self.mediaLibraryDataSource loadDataWithOptions:options success:successBlock failure:failureBlock];
        } failure:^(NSError *error) {
            [self.mediaLibraryDataSource loadDataWithOptions:options success:successBlock failure:failureBlock];
        }];
    } else {
        [self.currentDataSource loadDataWithOptions:options success:successBlock failure:^(NSError *error) {
            if ([error.domain isEqualToString:WPMediaPickerErrorDomain] &&
                (error.code == WPMediaPickerErrorCodePermissionDenied || error.code == WPMediaPickerErrorCodeRestricted)) {
                if (self.currentDataSource == self.deviceLibraryDataSource) {                
                    self.currentDataSource = self.mediaLibraryDataSource;
                    [self loadDataWithOptions:options success:successBlock failure:failureBlock];
                    return;
                }
            }
            if (failureBlock) {
                failureBlock(error);
            }
        }];
    }
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
