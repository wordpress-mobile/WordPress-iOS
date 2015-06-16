#import "WPAndDeviceMediaLibraryDataSource.h"
#import "MediaLibraryPickerDataSource.h"
#import "Blog.h"
#import "Post.h"

@interface WPAndDeviceMediaLibraryDataSource()
    @property (nonatomic, strong) MediaLibraryPickerDataSource *mediaLibraryDataSource;
    @property (nonatomic, strong) WPALAssetDataSource *deviceLibraryDataSource;
    @property (nonatomic, strong) id<WPMediaCollectionDataSource> currentDataSource;
    @property (nonatomic, strong) NSMutableDictionary *observers;
@end

@implementation WPAndDeviceMediaLibraryDataSource

- (instancetype)initWithBlog:(Blog *)blog
{
    self = [super init];
    if (self) {
        _mediaLibraryDataSource = [[MediaLibraryPickerDataSource alloc] initWithBlog:blog];
        _deviceLibraryDataSource = [[WPALAssetDataSource alloc] init];
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
        _deviceLibraryDataSource = [[WPALAssetDataSource alloc] init];
        _currentDataSource = _deviceLibraryDataSource;
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

- (id<NSObject>)registerChangeObserverBlock:(WPMediaChangesBlock)callback
{
    NSUUID *blockKey = [NSUUID UUID];
    id<NSObject> oneKey = [self.deviceLibraryDataSource registerChangeObserverBlock:callback];
    id<NSObject> secondKey = [self.mediaLibraryDataSource registerChangeObserverBlock:callback];
    
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
    [self.mediaLibraryDataSource registerChangeObserverBlock:keys[1]];
}

- (void)loadDataWithSuccess:(WPMediaChangesBlock)successBlock
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




@end
