#import "MediaLibraryPickerDataSource.h"
#import "Media.h"
#import "MediaService.h"
#import "Blog.h"
#import "ContextManager.h"
#import "Post.h"
#import "WordPress-swift.h"

@interface  MediaLibraryPickerDataSource()

@property (nonatomic, strong) MediaLibraryGroup *mediaGroup;
@property (nonatomic, strong) Blog *blog;
@property (nonatomic, strong) AbstractPost *post;
@property (nonatomic, assign) WPMediaType filter;
@property (nonatomic, assign) BOOL ascendingOrdering;
@property (nonatomic, strong) NSArray *media;
@property (nonatomic, strong) NSMutableDictionary *observers;
@property (nonatomic, strong) MediaService *mediaService;
@property (nonatomic, strong) id groupObserverHandler;
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
        _groupObserverHandler = [_mediaGroup registerChangeObserverBlock:^(BOOL incrementalChanges, NSIndexSet *removed, NSIndexSet *inserted, NSIndexSet *changed, NSArray<id<WPMediaMove>> *moved) {
            [self notifyObserversWithIncrementalChanges:incrementalChanges removed:removed inserted:inserted changed:changed moved:moved];
        }];
        _blog = blog;
        NSManagedObjectContext *backgroundContext = [[ContextManager sharedInstance] newDerivedContext];
        _mediaService = [[MediaService alloc] initWithManagedObjectContext:backgroundContext];
        _observers = [NSMutableDictionary dictionary];
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


-(NSInteger)numberOfAssets
{
    return [self.media count];
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

-(void)loadDataWithSuccess:(WPMediaSuccessBlock)successBlock failure:(WPMediaFailureBlock)failureBlock
{
    NSManagedObjectContext *mainContext = [[ContextManager sharedInstance] mainContext];
    [mainContext performBlock:^{
        NSString *entityName = NSStringFromClass([Media class]);
        NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:entityName];
        request.predicate = [[self class] predicateForFilter:self.filter blog:self.blog];
        NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"creationDate" ascending:self.ascendingOrdering];
        request.sortDescriptors = @[sortDescriptor];
        NSError *error;
        self.media = [mainContext executeFetchRequest:request error:&error];
    }];
    [self.mediaService syncMediaLibraryForBlog:self.blog success:^{
        NSManagedObjectContext *mainContext = [[ContextManager sharedInstance] mainContext];
        [mainContext performBlock:^{
            NSString *entityName = NSStringFromClass([Media class]);
            NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:entityName];
            request.predicate = [[self class] predicateForFilter:self.filter blog:self.blog];
            NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"creationDate" ascending:self.ascendingOrdering];
            request.sortDescriptors = @[sortDescriptor];
            NSError *error;
            self.media = [mainContext executeFetchRequest:request error:&error];
            if (self.media == nil && error) {
                DDLogVerbose(@"Error fecthing media: %@", [error localizedDescription]);
                if (failureBlock) {
                    failureBlock(error);
                }
                return;
            }
            if (successBlock) {
                successBlock();
            }
        }];
    } failure:^(NSError *error) {
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
    [self addAssetWithChangeRequest:^PHAssetChangeRequest *{
        NSString *fileName = [NSString stringWithFormat:@"%@_%@", [[NSProcessInfo processInfo] globallyUniqueString], @".jpg"];
        NSURL *fileURL = [NSURL fileURLWithPath:[NSTemporaryDirectory() stringByAppendingPathComponent:fileName]];
        NSError *error;
        if ([image writeToURL:fileURL type:(__bridge NSString *)kUTTypeJPEG compressionQuality:0.9 metadata:metadata error:&error]){
            return [PHAssetChangeRequest creationRequestForAssetFromImageAtFileURL:fileURL];
        }
        return nil;
    } completionBlock:completionBlock];
}

- (void)addVideoFromURL:(NSURL *)url
        completionBlock:(WPMediaAddedBlock)completionBlock
{
    [self addAssetWithChangeRequest:^PHAssetChangeRequest *{
        return [PHAssetChangeRequest creationRequestForAssetFromVideoAtFileURL:url];
    } completionBlock:completionBlock];
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
    return self.media[index];
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
    return media;
}

+ (NSPredicate *)predicateForFilter:(WPMediaType)filter blog:(Blog *)blog
{
    NSPredicate *predicate;
    switch (filter) {
        case WPMediaTypeImage: {
            predicate = [NSPredicate predicateWithFormat:@"mediaTypeString = %@ && blog = %@",  @"image", blog];
        } break;
        case WPMediaTypeVideo: {
            predicate = [NSPredicate predicateWithFormat:@"mediaTypeString = %@ && blog = %@", @"video", blog];
        } break;
        case WPMediaTypeVideoOrImage: {
            predicate = [NSPredicate predicateWithFormat:@"(mediaTypeString = %@ || mediaTypeString = %@)  && blog = %@", @"image", @"video", blog];
        } break;
        default:
            break;
    };
    return predicate;
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

- (NSInteger)numberOfAssets
{
    if (self.itemsCount == NSNotFound) {
        NSManagedObjectContext *mainContext = [[ContextManager sharedInstance] mainContext];
        MediaService *mediaService = [[MediaService alloc] initWithManagedObjectContext:mainContext];
        __weak __typeof__(self) weakSelf = self;
        [mediaService getMediaLibraryCountForBlog:self.blog
                                          success:^(NSInteger count) {
                                              weakSelf.itemsCount = count;
                                              [weakSelf notifyObserversWithIncrementalChanges:NO removed:nil inserted:nil changed:nil moved:nil];
                                          } failure:^(NSError *error) {
                                              DDLogError(@"%@", [error localizedDescription]);
                                          }];
    }
    return self.itemsCount;
}

@end

@implementation Media(WPMediaAsset)

- (WPMediaRequestID)imageWithSize:(CGSize)size completionHandler:(WPMediaImageBlock)completionHandler
{
    NSManagedObjectContext *mainContext = [[ContextManager sharedInstance] mainContext];
    MediaService *mediaService = [[MediaService alloc] initWithManagedObjectContext:mainContext];
    [mediaService thumbnailForMedia:self size:size success:^(UIImage *image) {
        if (completionHandler) {
            completionHandler(image, nil);
        }
    } failure:^(NSError *error) {
        if (completionHandler) {
            completionHandler(nil, error);
        }
    }];

    return [self.mediaID intValue];
}

- (void)cancelImageRequest:(WPMediaRequestID)requestID
{

}

- (WPMediaType)assetType
{
    if (self.mediaType == MediaTypeImage) {
        return WPMediaTypeImage;
    } else if (self.mediaType == MediaTypeVideo) {
        return WPMediaTypeVideo;
    } else {
        return WPMediaTypeOther;
    }
}

- (NSTimeInterval)duration
{
    if (self.mediaType != MediaTypeVideo) {
        return 0;
    }
    if (self.length != nil && [self.length doubleValue] > 0) {
        return [self.length doubleValue];
    }
    
    if (self.absoluteLocalURL == nil ||
        ![[NSFileManager defaultManager] fileExistsAtPath:self.absoluteLocalURL isDirectory:nil]) {
        return 0;
    }
    NSURL *sourceMovieURL = [NSURL fileURLWithPath:self.absoluteLocalURL];
    AVURLAsset *sourceAsset = [AVURLAsset URLAssetWithURL:sourceMovieURL options:nil];
    CMTime duration = sourceAsset.duration;
    
    return CMTimeGetSeconds(duration);
}

- (NSDate *)date
{
    return self.creationDate;
}

- (id)baseAsset
{
    return self;
}

- (NSString *)identifier
{
    return [[self.objectID URIRepresentation] absoluteString];
}

@end