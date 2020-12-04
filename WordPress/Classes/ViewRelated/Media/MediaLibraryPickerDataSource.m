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
@property (nonatomic, strong) NSMutableDictionary *groupObservers;
@property (nonatomic, strong) NSFetchedResultsController *fetchController;
@property (nonatomic, strong) id groupObserverHandler;
#pragma mark - change trackers
@property (nonatomic, strong) NSMutableIndexSet *mediaRemoved;
@property (nonatomic, strong) NSMutableIndexSet *mediaInserted;
@property (nonatomic, strong) NSMutableIndexSet *mediaChanged;
@property (nonatomic, strong) NSMutableArray *mediaMoved;

@end

@implementation MediaLibraryPickerDataSource

- (instancetype)initWithBlog:(Blog *)blog
{
    /// Temporary logging to try and narrow down an issue:
    ///
    /// REF: https://github.com/wordpress-mobile/WordPress-iOS/issues/15335
    ///
    if (blog == nil || blog.objectID == nil) {
        DDLogError(@"🔴 Error: missing object ID (please contact @diegoreymendez with this log)");
        DDLogError(@"%@", [NSThread callStackSymbols]);
    }
    
    self = [super init];
    if (self) {
        _mediaGroup = [[MediaLibraryGroup alloc] initWithBlog:blog];
        _blog = blog;
        _observers = [NSMutableDictionary dictionary];
        _groupObservers = [NSMutableDictionary dictionary];
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

#pragma mark - WPMediaCollectionDataSource

- (void)searchFor:(NSString *)searchText
{
    if (![_searchQuery isEqualToString:searchText]) {
        _searchQuery = [searchText copy];

        _fetchController = nil;
        [self.fetchController performFetch:nil];
        [self notifyObserversReloadData];
    }
}

- (void)setFilter:(WPMediaType)filter {
    if ( _filter != filter ) {
        _filter = filter;
        
        _fetchController = nil;
        [self.fetchController performFetch:nil];
    }
}

- (void)searchCancelled
{
    _searchQuery = nil;
    _fetchController = nil;
    [self.fetchController performFetch:nil];
}

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

- (void)loadDataWithOptions:(WPMediaLoadOptions)options success:(WPMediaSuccessBlock)successBlock failure:(WPMediaFailureBlock)failureBlock
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
    MediaCoordinator *mediaCoordinator = [MediaCoordinator shared];

    /// Temporary logging to try and narrow down an issue:
    ///
    /// REF: https://github.com/wordpress-mobile/WordPress-iOS/issues/15335
    ///
    if (self.blog == nil || self.blog.objectID == nil) {
        DDLogError(@"🔴 Error: missing object ID (please contact @diegoreymendez with this log)");
        DDLogError(@"%@", [NSThread callStackSymbols]);
    }
    
    __block BOOL ignoreSyncError = self.ignoreSyncErrors;
    [mediaCoordinator syncMediaFor:self.blog
                           success:^{
                               if (!localResultsAvailable && successBlock) {
                                   successBlock();
                               }
                           } failure:^(NSError * _Nonnull error) {
                               if (ignoreSyncError && successBlock) {
                                   successBlock();
                                   return;
                               }

                               if (failureBlock) {
                                   failureBlock(error);
                               }
                           }];
}

- (void)notifyObserversWithIncrementalChanges:(BOOL)incrementalChanges removed:(NSIndexSet *)removed inserted:(NSIndexSet *)inserted changed:(NSIndexSet *)changed moved:(NSArray<id<WPMediaMove>> *)moved
{
    for ( WPMediaChangesBlock callback in [self.observers allValues]) {
        callback(incrementalChanges, removed, inserted, changed, moved);
    }
}

- (void)notifyGroupObservers
{
    for ( WPMediaGroupChangesBlock callback in [self.groupObservers allValues]) {
        callback();
    }
}

- (void)notifyObserversReloadData
{
    [self notifyObserversWithIncrementalChanges:NO
                                        removed:[NSIndexSet new]
                                       inserted:[NSIndexSet new]
                                        changed:[NSIndexSet new]
                                          moved:@[]];
}

-(id<NSObject>)registerChangeObserverBlock:(WPMediaChangesBlock)callback
{
    NSUUID *blockKey = [NSUUID UUID];
    [self.observers setObject:[callback copy] forKey:blockKey];
    return blockKey;

}

-(void)unregisterChangeObserver:(id<NSObject>)blockKey
{
    if (blockKey) {
        [self.observers removeObjectForKey:blockKey];
    }
}

-(id<NSObject>)registerGroupChangeObserverBlock:(WPMediaGroupChangesBlock)callback
{
    NSUUID *blockKey = [NSUUID UUID];
    [self.groupObservers setObject:[callback copy] forKey:blockKey];
    return blockKey;}

-(void)unregisterGroupChangeObserver:(id<NSObject>)blockKey
{
    if (blockKey) {
        [self.groupObservers removeObjectForKey:blockKey];
    }
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
            if ([image writeToURL:fileURL type:(__bridge NSString *)kUTTypeJPEG compressionQuality:MediaImportService.preferredImageCompressionQuality metadata:metadata error:&error]){
                return [PHAssetChangeRequest creationRequestForAssetFromImageAtFileURL:fileURL];
            }
            return nil;
        } completionBlock:completionBlock];
    } else {
        NSString *fileName = [NSString stringWithFormat:@"%@_%@", [[NSProcessInfo processInfo] globallyUniqueString], @".jpg"];        
        NSURL *fileURL = [NSURL fileURLWithPath:[NSTemporaryDirectory() stringByAppendingPathComponent:fileName]];
        NSError *error;
        if ([image writeToURL:fileURL type:(__bridge NSString *)kUTTypeJPEG compressionQuality:MediaImportService.preferredImageCompressionQuality metadata:metadata error:&error]){
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

- (void)addAssetWithChangeRequest:(PHAssetChangeRequest *(^)(void))changeRequestBlock
                  completionBlock:(WPMediaAddedBlock)completionBlock
{
    NSParameterAssert(changeRequestBlock);
    __block NSString * assetIdentifier = nil;
    __weak __typeof__(self) weakSelf = self;
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
        [weakSelf addMediaFromAssetIdentifier:assetIdentifier completionBlock:completionBlock];
    }];
}

-(void)addMediaFromAssetIdentifier:(NSString *)assetIdentifier
            completionBlock:(WPMediaAddedBlock)completionBlock
{
    NSManagedObjectID *objectID = [self.post objectID];
    if (objectID == nil) {
        objectID = [self.blog objectID];
    }
    PHFetchResult *result = [PHAsset fetchAssetsWithLocalIdentifiers:@[assetIdentifier] options:nil];
    PHAsset *asset = [result firstObject];
    MediaService *mediaService = [[MediaService alloc] initWithManagedObjectContext:self.blog.managedObjectContext];
    [mediaService createMediaWith:asset blog:self.blog post: self.post progress:nil thumbnailCallback:nil completion:^(Media *media, NSError *error) {
        [self loadDataWithOptions:WPMediaLoadOptionsAssets success:^{
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
    MediaService *mediaService = [[MediaService alloc] initWithManagedObjectContext:self.blog.managedObjectContext];
    [mediaService createMediaWith:url
                     blog:self.blog
                     post:self.post
                         progress:nil
                   thumbnailCallback:nil
                          completion:^(Media *media, NSError *error) {
        [self loadDataWithOptions:WPMediaLoadOptionsAssets success:^{
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
    NSMutableArray *mediaPredicates = [NSMutableArray new];

    if ((filter & WPMediaTypeAll) == WPMediaTypeAll) {
        [mediaPredicates addObject:[NSPredicate predicateWithValue:YES]];
    } else {
        if (filter & WPMediaTypeImage) {
            [mediaPredicates addObject:[NSPredicate predicateWithFormat:@"mediaTypeString == %@", [Media stringFromMediaType:MediaTypeImage]]];
        }
        if ( filter & WPMediaTypeVideo) {
            [mediaPredicates addObject:[NSPredicate predicateWithFormat:@"mediaTypeString == %@", [Media stringFromMediaType:MediaTypeVideo]]];
        }
        if ( filter & WPMediaTypeAudio) {
            [mediaPredicates addObject:[NSPredicate predicateWithFormat:@"mediaTypeString == %@", [Media stringFromMediaType:MediaTypeAudio]]];
        }
    }

    NSCompoundPredicate *mediaPredicate = [NSCompoundPredicate orPredicateWithSubpredicates:mediaPredicates];

    return [NSCompoundPredicate andPredicateWithSubpredicates:@[predicate, mediaPredicate]];
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

    if (!self.includeUnsyncedMedia) {
        NSPredicate *statusPredicate = [NSPredicate predicateWithFormat:@"%K == %@", @"remoteStatusNumber", @(MediaRemoteStatusSync)];
        fetchRequest.predicate = [NSCompoundPredicate andPredicateWithSubpredicates:@[fetchRequest.predicate, statusPredicate]];
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
    if ([self.mediaChanged containsIndex:0] || [self.mediaInserted containsIndex:0] || [self.mediaRemoved containsIndex:0]) {
        [self notifyGroupObservers];
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
@end

@implementation MediaLibraryGroup

- (instancetype)initWithBlog:(Blog *)blog
{
    self = [super init];
    if (self) {
        _blog = blog;
        _filter = WPMediaTypeAll;
        _itemsCount = NSNotFound;        
    }
    return self;
}

- (id)baseGroup
{
    return self;
}

- (NSString *)name
{
    return NSLocalizedString(@"WordPress Media", @"Name for the WordPress Media Library");
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

- (NSInteger)numberOfAssetsOfType:(WPMediaType)mediaType completionHandler:(WPMediaCountBlock)completionHandler
{
    NSMutableSet *mediaTypes = [NSMutableSet set];
    if (mediaType & WPMediaTypeImage) {
        [mediaTypes addObject:@(MediaTypeImage)];
    }
    if (mediaType & WPMediaTypeVideo) {
        [mediaTypes addObject:@(MediaTypeVideo)];
    }
    if (mediaType & WPMediaTypeAudio) {
        [mediaTypes addObject:@(MediaTypeAudio)];
    }

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
        completionHandler(count, nil);
    } failure:^(NSError * _Nonnull error) {
        DDLogError(@"%@", [error localizedDescription]);
        weakSelf.itemsCount = count;
        completionHandler(count, error);
    }];

    return self.itemsCount;
}

@end
