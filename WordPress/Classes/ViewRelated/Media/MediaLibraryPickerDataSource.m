#import "MediaLibraryPickerDataSource.h"
#import "Media.h"
#import "MediaService.h"
#import "Blog.h"
#import "ContextManager.h"
#import "WordPress-Swift.h"

@interface  MediaLibraryPickerDataSource() <NSFetchedResultsControllerDelegate>

@property (nonatomic, strong) MediaLibraryGroup *mediaGroup;
@property (nonatomic, strong) Blog *blog;
@property (nonatomic, strong) AbstractPost *post;
@property (nonatomic, assign) WPMediaType filter;
@property (nonatomic, assign) BOOL ascendingOrdering;
@property (nonatomic, strong) NSMutableDictionary *observers;
@property (nonatomic, strong) NSFetchedResultsController *fetchController;
@property (nonatomic, strong) id groupObserverHandler;
#pragma mark - change trackers
@property (nonatomic, strong) NSMutableIndexSet *mediaRemoved;
@property (nonatomic, strong) NSMutableIndexSet *mediaInserted;
@property (nonatomic, strong) NSMutableIndexSet *mediaChanged;
@property (nonatomic, strong) NSMutableArray *mediaMoved;

@end

@implementation MediaLibraryPickerDataSource

- (void)dealloc
{
    [_mediaGroup unregisterChangeObserver:_groupObserverHandler];
}

- (instancetype)initWithBlog:(Blog *)blog
{
    self = [super init];
    if (self) {
        _mediaGroup = [[MediaLibraryGroup alloc] initWithBlog:blog];
        __weak __typeof__(self) weakSelf = self;
        _groupObserverHandler = [_mediaGroup registerChangeObserverBlock:^(BOOL incrementalChanges, NSIndexSet *removed, NSIndexSet *inserted, NSIndexSet *changed, NSArray<id<WPMediaMove>> *moved) {
            [weakSelf notifyObserversWithIncrementalChanges:incrementalChanges removed:removed inserted:inserted changed:changed moved:moved];
        }];
        _blog = blog;
        _observers = [NSMutableDictionary dictionary];

        _mediaRemoved = [[NSMutableIndexSet alloc] init];
        _mediaInserted = [[NSMutableIndexSet alloc] init];
        _mediaChanged = [[NSMutableIndexSet alloc] init];
        _mediaMoved = [[NSMutableArray alloc] init];

    }
    return self;
}

- (instancetype)initWithPost:(AbstractPost *)post
{
    self = [self initWithBlog:post.blog];
    if (self) {
        _post = post;
    }
    return self;
}


- (instancetype)init
{
    return [self initWithBlog:nil];
}

- (void)setIsPaused:(BOOL)isPaused
{
    if (_isPaused != isPaused) {
        _isPaused = isPaused;

        if (isPaused) {
            _fetchController.delegate = nil;
            _fetchController = nil;
        } else {
            [self.fetchController performFetch:nil];
        }
    }

    return;
}

#pragma mark - WPMediaCollectionDataSource

-(NSInteger)numberOfAssets
{
    if ([[self.fetchController sections] count] > 0) {
        id <NSFetchedResultsSectionInfo> sectionInfo = [[self.fetchController sections] objectAtIndex:0];
        return [sectionInfo numberOfObjects];
    } else
        return 0;
}

-(NSInteger)numberOfGroups
{
    return 1;
}

-(void)setSelectedGroup:(id<WPMediaGroup>)group
{
    //There is only one group in the media library for now so don't do anything
}

-(id<WPMediaGroup>)selectedGroup
{
   //There is only one group in the media library for now so don't do anything
   return self.mediaGroup;
}

- (id<WPMediaGroup>)groupAtIndex:(NSInteger)index
{
    return self.mediaGroup;
}

- (void)loadDataWithSuccess:(WPMediaSuccessBlock)successBlock failure:(WPMediaFailureBlock)failureBlock
{
    // let's check if we already have fetched results before
    if (self.fetchController.fetchedObjects == nil) {
        NSError *error;
        if (![self.fetchController performFetch:&error]) {
            if (failureBlock) {
                failureBlock(error);
            }
            return;
        }
    }
    BOOL localResultsAvailable = NO;
    if (self.fetchController.fetchedObjects.count > 0) {
        localResultsAvailable = YES;
        if (successBlock) {
            successBlock();
        }
    }
    // try to sync from the server
    NSManagedObjectContext *backgroundContext = [[ContextManager sharedInstance] newDerivedContext];
    MediaService *mediaService = [[MediaService alloc] initWithManagedObjectContext:backgroundContext];
    [mediaService syncMediaLibraryForBlog:self.blog success:^{
        if (!localResultsAvailable && successBlock) {
            successBlock();
        }
    } failure:failureBlock];
}

- (void)notifyObserversWithIncrementalChanges:(BOOL)incrementalChanges removed:(NSIndexSet *)removed inserted:(NSIndexSet *)inserted changed:(NSIndexSet *)changed moved:(NSArray<id<WPMediaMove>> *)moved
{
    for ( WPMediaChangesBlock callback in [self.observers allValues]) {
        callback(incrementalChanges, removed, inserted, changed, moved);
    }
}

-(id<NSObject>)registerChangeObserverBlock:(WPMediaChangesBlock)callback
{
    NSUUID *blockKey = [NSUUID UUID];
    [self.observers setObject:[callback copy] forKey:blockKey];
    return blockKey;

}

-(void)unregisterChangeObserver:(id<NSObject>)blockKey
{
    [self.observers removeObjectForKey:blockKey];
}

- (void)addImage:(UIImage *)image
        metadata:(NSDictionary *)metadata
 completionBlock:(WPMediaAddedBlock)completionBlock
{
    if ( PHPhotoLibrary.authorizationStatus == PHAuthorizationStatusAuthorized ) {
        [self addAssetWithChangeRequest:^PHAssetChangeRequest *{
            NSString *fileName = [NSString stringWithFormat:@"%@_%@", [[NSProcessInfo processInfo] globallyUniqueString], @".jpg"];
            NSURL *fileURL = [NSURL fileURLWithPath:[NSTemporaryDirectory() stringByAppendingPathComponent:fileName]];
            NSError *error;
            if ([image writeToURL:fileURL type:(__bridge NSString *)kUTTypeJPEG compressionQuality:0.9 metadata:metadata error:&error]){
                return [PHAssetChangeRequest creationRequestForAssetFromImageAtFileURL:fileURL];
            }
            return nil;
        } completionBlock:completionBlock];
    } else {
        NSString *fileName = [NSString stringWithFormat:@"%@_%@", [[NSProcessInfo processInfo] globallyUniqueString], @".jpg"];        
        NSURL *fileURL = [NSURL fileURLWithPath:[NSTemporaryDirectory() stringByAppendingPathComponent:fileName]];
        NSError *error;
        if ([image writeToURL:fileURL type:(__bridge NSString *)kUTTypeJPEG compressionQuality:0.9 metadata:metadata error:&error]){
            [self addMediaFromURL:fileURL completionBlock:completionBlock];
        } else {
            if (completionBlock) {
                completionBlock(nil, error);
            }
        }
    }
}

- (void)addVideoFromURL:(NSURL *)url
        completionBlock:(WPMediaAddedBlock)completionBlock
{
    if ( PHPhotoLibrary.authorizationStatus == PHAuthorizationStatusAuthorized ) {
        [self addAssetWithChangeRequest:^PHAssetChangeRequest *{
            return [PHAssetChangeRequest creationRequestForAssetFromVideoAtFileURL:url];
        } completionBlock:completionBlock];
    } else {
        [self addMediaFromURL:url completionBlock:completionBlock];
    }
}

- (void)addAssetWithChangeRequest:(PHAssetChangeRequest *(^)())changeRequestBlock
                  completionBlock:(WPMediaAddedBlock)completionBlock
{
    NSParameterAssert(changeRequestBlock);
    __block NSString * assetIdentifier = nil;
    [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
        // Request creating an asset from the image.
        PHAssetChangeRequest *createAssetRequest = changeRequestBlock();
        PHObjectPlaceholder *assetPlaceholder = [createAssetRequest placeholderForCreatedAsset];
        assetIdentifier = [assetPlaceholder localIdentifier];
    } completionHandler:^(BOOL success, NSError *error) {
        if (!success) {
            if (completionBlock){
                dispatch_async(dispatch_get_main_queue(), ^{
                    completionBlock(nil, error);
                });
            }
            return;
        }
        [self addMediaFromAssetIdentifier:assetIdentifier completionBlock:completionBlock];
    }];
}

-(void)addMediaFromAssetIdentifier:(NSString *)assetIdentifier
            completionBlock:(WPMediaAddedBlock)completionBlock
{
    NSManagedObjectID *objectID = [self.post objectID];
    PHFetchResult *result = [PHAsset fetchAssetsWithLocalIdentifiers:@[assetIdentifier] options:nil];
    PHAsset *asset = [result firstObject];
    MediaService *mediaService = [[MediaService alloc] initWithManagedObjectContext:self.blog.managedObjectContext];
    [mediaService createMediaWithPHAsset:asset forPostObjectID:objectID thumbnailCallback:nil completion:^(Media *media, NSError *error) {
        [self loadDataWithSuccess:^{
            completionBlock(media, error);
        } failure:^(NSError *error) {
            if (completionBlock) {
                completionBlock(nil, error);
            }
        }];
    }];
}

-(void)addMediaFromURL:(NSURL *)url
           completionBlock:(WPMediaAddedBlock)completionBlock
{
    NSManagedObjectID *objectID = [self.post objectID];
    MediaService *mediaService = [[MediaService alloc] initWithManagedObjectContext:self.blog.managedObjectContext];
    [mediaService createMediaWithURL:url
                     forPostObjectID:objectID
                   thumbnailCallback:nil
                          completion:^(Media *media, NSError *error) {
        [self loadDataWithSuccess:^{
            completionBlock(media, error);
        } failure:^(NSError *error) {
            if (completionBlock) {
                completionBlock(nil, error);
            }
        }];
    }];
}

-(void)setMediaTypeFilter:(WPMediaType)filter
{
    self.filter = filter;
    self.mediaGroup.filter = filter;
}

-(WPMediaType)mediaTypeFilter
{
    return self.filter;
}

-(id<WPMediaAsset>)mediaAtIndex:(NSInteger)index
{
    return [self.fetchController objectAtIndexPath:[NSIndexPath indexPathForRow:index inSection:0]];
}

-(id<WPMediaAsset>)mediaWithIdentifier:(NSString *)identifier
{
    if (!identifier) {
        return nil;
    }
    NSManagedObjectContext *mainContext = [[ContextManager sharedInstance] mainContext];
    __block Media *media = nil;
    NSURL *assetURL = [NSURL URLWithString:identifier];
    if (!assetURL) {
        return nil;
    }
    if (![[assetURL scheme] isEqualToString:@"x-coredata"]){
        return nil;
    }
    [mainContext performBlockAndWait:^{
        NSManagedObjectID *assetID = [[[ContextManager sharedInstance] persistentStoreCoordinator] managedObjectIDForURIRepresentation:assetURL];
        media = (Media *)[mainContext objectWithID:assetID];
    }];

    return (!media.isDeleted) ? media : nil;
}

#pragma mark - NSFetchedResultsController helpers

+ (NSPredicate *)predicateForFilter:(WPMediaType)filter blog:(Blog *)blog
{
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"%K == %@", @"blog", blog];
    NSPredicate *mediaPredicate = [NSPredicate predicateWithValue:YES];
    NSPredicate *statusPredicate = [NSPredicate predicateWithFormat:@"%K == %@", @"remoteStatusNumber", @(MediaRemoteStatusSync)];
    switch (filter) {
        case WPMediaTypeImage: {
            mediaPredicate = [NSPredicate predicateWithFormat:@"mediaTypeString == %@", [Media stringFromMediaType:MediaTypeImage]];
        } break;
        case WPMediaTypeVideo: {
            mediaPredicate = [NSPredicate predicateWithFormat:@"mediaTypeString == %@", [Media stringFromMediaType:MediaTypeVideo]];
        } break;
        case WPMediaTypeVideoOrImage: {
            mediaPredicate = [NSPredicate predicateWithFormat:@"(mediaTypeString == %@ || mediaTypeString == %@)", [Media stringFromMediaType:MediaTypeImage], [Media stringFromMediaType:MediaTypeVideo]];
        } break;
        default:
            break;
    };
    return [NSCompoundPredicate andPredicateWithSubpredicates:
            @[predicate, mediaPredicate, statusPredicate]];
}

- (NSPredicate *)predicateForSearchQuery
{
    if (self.searchQuery && [self.searchQuery length] > 0) {
        return [NSPredicate predicateWithFormat:@"(title CONTAINS[cd] %@) OR (caption CONTAINS[cd] %@) OR (desc CONTAINS[cd] %@)", self.searchQuery, self.searchQuery, self.searchQuery];
    }

    return nil;
}

- (void)setSearchQuery:(NSString *)searchQuery
{
    if (![_searchQuery isEqualToString:searchQuery]) {
        _searchQuery = [searchQuery copy];

        _fetchController = nil;
        [self.fetchController performFetch:nil];
    }
}

- (NSFetchedResultsController *)fetchController
{
    if (_fetchController) {
        return _fetchController;
    }

    NSManagedObjectContext *mainContext = [[ContextManager sharedInstance] mainContext];
    NSString *entityName = NSStringFromClass([Media class]);
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:entityName];

    NSPredicate *filterPredicate = [[self class] predicateForFilter:self.filter blog:self.blog];
    NSPredicate *searchPredicate = [self predicateForSearchQuery];
    if (searchPredicate) {
        fetchRequest.predicate = [NSCompoundPredicate andPredicateWithSubpredicates:@[filterPredicate, searchPredicate]];
    } else {
        fetchRequest.predicate = filterPredicate;
    }

    NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"creationDate" ascending:self.ascendingOrdering];
    fetchRequest.sortDescriptors = @[sortDescriptor];

    _fetchController = [[NSFetchedResultsController alloc]
                            initWithFetchRequest:fetchRequest
                            managedObjectContext:mainContext
                            sectionNameKeyPath:nil
                            cacheName:nil];
    _fetchController.delegate = self;

    return _fetchController;
}

- (NSInteger)totalAssetCount
{
    NSManagedObjectContext *mainContext = [[ContextManager sharedInstance] mainContext];
    NSString *entityName = NSStringFromClass([Media class]);
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:entityName];
    fetchRequest.predicate = [[self class] predicateForFilter:self.filter blog:self.blog];

    return (NSInteger)[mainContext countForFetchRequest:fetchRequest
                                                  error:nil];
}

#pragma mark - NSFetchedResultsControllerDelegate

- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller {
    [self.mediaRemoved removeAllIndexes];
    [self.mediaInserted removeAllIndexes];
    [self.mediaChanged removeAllIndexes];
    [self.mediaMoved removeAllObjects];
}


- (void)controller:(NSFetchedResultsController *)controller didChangeSection:(id <NSFetchedResultsSectionInfo>)sectionInfo
           atIndex:(NSUInteger)sectionIndex forChangeType:(NSFetchedResultsChangeType)type {
    //This shouldn't be called because we don't have changes to sections.
}


- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject
       atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type
      newIndexPath:(NSIndexPath *)newIndexPath
{
    switch(type) {

        case NSFetchedResultsChangeInsert:
            [self.mediaInserted addIndex:newIndexPath.row];
        break;
        case NSFetchedResultsChangeDelete:
            [self.mediaRemoved addIndex:indexPath.row];
        break;
        case NSFetchedResultsChangeUpdate:
            [self.mediaChanged addIndex:indexPath.row];
        break;

        case NSFetchedResultsChangeMove: {
            WPIndexMove *mediaMove = [[WPIndexMove alloc] init:indexPath.row to:newIndexPath.row];
            [self.mediaMoved addObject:mediaMove];
        }
        break;
    }
}


- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller {
    if (self.mediaRemoved.count == 0 && self.mediaInserted.count == 0) {
        //if it's not a removal or insertion we can ignore. We do this because
        // every time we request get a new thumbnail beside getting it from the internet we
            // are saving a reference to the database/coredata and triggering another fetch result controller udpate
        return;
    }
    [self notifyObserversWithIncrementalChanges:YES
                                        removed:self.mediaRemoved
                                       inserted:self.mediaInserted
                                        changed:self.mediaChanged
                                          moved:self.mediaMoved];
}

@end

@interface MediaLibraryGroup()
    @property (nonatomic, strong) Blog *blog;
    @property (nonatomic, assign) NSInteger itemsCount;
    @property (nonatomic, strong) NSMutableDictionary *observers;
@end

@implementation MediaLibraryGroup

- (instancetype)initWithBlog:(Blog *)blog
{
    self = [super init];
    if (self) {
        _blog = blog;
        _filter = WPMediaTypeAll;
        _itemsCount = NSNotFound;
        _observers = [NSMutableDictionary dictionary];
    }
    return self;
}

- (void)notifyObserversWithIncrementalChanges:(BOOL)incrementalChanges removed:(NSIndexSet *)removed inserted:(NSIndexSet *)inserted changed:(NSIndexSet *)changed moved:(NSArray<id<WPMediaMove>> *)moved
{
    for ( WPMediaChangesBlock callback in [self.observers allValues]) {
        callback(incrementalChanges, removed, inserted, changed, moved);
    }
}

-(id<NSObject>)registerChangeObserverBlock:(WPMediaChangesBlock)callback
{
    NSUUID *blockKey = [NSUUID UUID];
    [self.observers setObject:[callback copy] forKey:blockKey];
    return blockKey;
    
}

-(void)unregisterChangeObserver:(id<NSObject>)blockKey
{
    [self.observers removeObjectForKey:blockKey];
}

- (id)baseGroup
{
    return self;
}

- (NSString *)name
{
    return NSLocalizedString(@"Media Library", @"Name for the WordPress Media Library");
}

- (WPMediaRequestID)imageWithSize:(CGSize)size completionHandler:(WPMediaImageBlock)completionHandler
{
    NSString *entityName = NSStringFromClass([Media class]);
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:entityName];
    request.predicate = [MediaLibraryPickerDataSource predicateForFilter:self.filter blog:self.blog];
    NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"creationDate" ascending:NO];
    request.sortDescriptors = @[sortDescriptor];
    NSError *error;
    NSArray *mediaAssets = [[[ContextManager sharedInstance] mainContext] executeFetchRequest:request error:&error];
    if (mediaAssets.count == 0)
    {
        if (completionHandler){
            completionHandler(nil, nil);
        }
    }
    Media *media = [mediaAssets firstObject];
    if (!media) {
        UIImage *placeholderImage = [UIImage imageNamed:@"WordPress-share"];
        completionHandler(placeholderImage, nil);
        return 0;
    }
    return [media imageWithSize:size completionHandler:completionHandler];
}

- (void)cancelImageRequest:(WPMediaRequestID)requestID
{
    
}

- (NSString *)identifier
{
    return @"org.wordpress.medialibrary";
}

- (NSInteger)numberOfAssetsOfType:(WPMediaType)mediaType
{
    NSSet *mediaTypes = [NSMutableSet set];
    switch (mediaType) {
        case WPMediaTypeImage: {
            mediaTypes = [NSSet setWithArray:@[@(MediaTypeImage)]];
        } break;
        case WPMediaTypeVideo: {
            mediaTypes = [NSSet setWithArray:@[@(MediaTypeVideo)]];
        } break;
        case WPMediaTypeVideoOrImage: {
            mediaTypes = [NSSet setWithArray:@[@(MediaTypeImage), @(MediaTypeVideo)]];
        } break;
        default:
            break;
    };

    NSManagedObjectContext *mainContext = [[ContextManager sharedInstance] newDerivedContext];
    MediaService *mediaService = [[MediaService alloc] initWithManagedObjectContext:mainContext];
    NSInteger count = [mediaService getMediaLibraryCountForBlog:self.blog
                                                  forMediaTypes:mediaTypes];
    // If we have a count diferent of zero assume it's correct but sync with the server always in the background
    if (count != 0) {
        self.itemsCount = count;
    }
    __weak __typeof__(self) weakSelf = self;
    [mediaService getMediaLibraryServerCountForBlog:self.blog forMediaTypes:mediaTypes success:^(NSInteger count) {
        weakSelf.itemsCount = count;
    } failure:^(NSError * _Nonnull error) {
        DDLogError(@"%@", [error localizedDescription]);
        weakSelf.itemsCount = count;
    }];

    return self.itemsCount;
}

@end
