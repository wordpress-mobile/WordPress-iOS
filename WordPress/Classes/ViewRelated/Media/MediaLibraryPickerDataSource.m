#import "MediaLibraryPickerDataSource.h"
#import "Media.h"
#import "MediaService.h"
#import "Blog.h"
#import "ContextManager.h"
#import "Post.h"

@interface  MediaLibraryPickerDataSource()

@property (nonatomic, strong) MediaLibraryGroup *mediaGroup;
@property (nonatomic, strong) Blog *blog;
@property (nonatomic, strong) AbstractPost *post;
@property (nonatomic, assign) WPMediaType filter;
@property (nonatomic, strong) NSArray *media;
@property (nonatomic, strong) ALAssetsLibrary *assetsLibrary;

@end

@implementation MediaLibraryPickerDataSource

- (instancetype)initWithBlog:(Blog *)blog
{
    self = [super init];
    if (self) {
        _mediaGroup = [[MediaLibraryGroup alloc] initWithBlog:blog];
        _blog = blog;
        _assetsLibrary = [[ALAssetsLibrary alloc] init];
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

-(void)loadDataWithSuccess:(WPMediaChangesBlock)successBlock failure:(WPMediaFailureBlock)failureBlock
{
    NSString *entityName = NSStringFromClass([Media class]);
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:entityName];
    request.predicate = [[self class] predicateForFilter:self.filter];
    NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"creationDate" ascending:YES];
    request.sortDescriptors = @[sortDescriptor];
    NSError *error;
    self.media = [[[ContextManager sharedInstance] mainContext] executeFetchRequest:request error:&error];
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
}

-(id<NSObject>)registerChangeObserverBlock:(WPMediaChangesBlock)callback
{
    return nil;
}

-(void)unregisterChangeObserver:(id<NSObject>)blockKey
{

}

-(void)addImage:(UIImage *)image metadata:(NSDictionary *)metadata completionBlock:(WPMediaAddedBlock)completionBlock
{
    [self.assetsLibrary writeImageToSavedPhotosAlbum:[image CGImage]
                                            metadata:metadata
                                     completionBlock:^(NSURL *assetURL, NSError *error)
     {
         [self addMediaFromAssetURL:assetURL error:error completionBlock:completionBlock];
     }];
}

-(void)addVideoFromURL:(NSURL *)url completionBlock:(WPMediaAddedBlock)completionBlock
{
    [self.assetsLibrary writeVideoAtPathToSavedPhotosAlbum:url
                                           completionBlock:^(NSURL *assetURL, NSError *error)
     {
         [self addMediaFromAssetURL:assetURL error:error completionBlock:completionBlock];
     }];
}

-(void)addMediaFromAssetURL:(NSURL *)assetURL
                      error:(NSError *)error
            completionBlock:(WPMediaAddedBlock)completionBlock
{
    if (error) {
        if (completionBlock) {
            completionBlock(nil, error);
        }
        return;
    }
    NSManagedObjectID *objectID = [self.post objectID];
    [self.assetsLibrary assetForURL:assetURL resultBlock:^(ALAsset *asset) {
        MediaService *mediaService = [[MediaService alloc] initWithManagedObjectContext:self.blog.managedObjectContext];
        [mediaService createMediaWithAsset:asset forPostObjectID:objectID completion:^(Media *media, NSError *error) {
            [self loadDataWithSuccess:^{
                completionBlock(media, error);
            } failure:^(NSError *error) {
                if (completionBlock) {
                    completionBlock(nil, error);
                }
            }];
        }];
    } failureBlock:^(NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (completionBlock) {
                completionBlock(nil, error);
            }
        });
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

+ (NSPredicate *)predicateForFilter:(WPMediaType)filter
{
    NSPredicate *predicate;
    switch (filter) {
        case WPMediaTypeImage: {
            predicate = [NSPredicate predicateWithFormat:@"mediaTypeString = %@", @"image"];
        } break;
        case WPMediaTypeVideo: {
            predicate = [NSPredicate predicateWithFormat:@"mediaTypeString = %@", @"video"];
        } break;
        case WPMediaTypeAll: {
            predicate = [NSPredicate predicateWithFormat:@"(mediaTypeString = %@ || mediaTypeString = %@) ", @"image", @"video"];
        } break;
        default:
            break;
    };
    return predicate;
}

@end

@interface MediaLibraryGroup()
    @property (nonatomic, strong) Blog *blog;
@end

@implementation MediaLibraryGroup

- (instancetype)initWithBlog:(Blog *)blog
{
    self = [super init];
    if (self) {
        _blog = blog;
        _filter = WPMediaTypeAll;
    }
    return self;
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
    request.predicate = [MediaLibraryPickerDataSource predicateForFilter:self.filter];
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
    NSString *entityName = NSStringFromClass([Media class]);
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:entityName];
    request.predicate = [MediaLibraryPickerDataSource predicateForFilter:self.filter];
    NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"creationDate" ascending:NO];
    request.sortDescriptors = @[sortDescriptor];
    NSError *error;
    NSUInteger count = [[[ContextManager sharedInstance] mainContext] countForFetchRequest:request error:&error];
    return count;
}

@end

@implementation Media(WPMediaAsset)

- (WPMediaRequestID)imageWithSize:(CGSize)size completionHandler:(WPMediaImageBlock)completionHandler
{
    NSString *pathForFile;
    if (self.mediaType == MediaTypeImage) {
        pathForFile = self.absoluteLocalURL;
    } else if (self.mediaType == MediaTypeVideo) {
        pathForFile = self.thumbnailLocalURL;
    }
    if (pathForFile) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            UIImage *image = [UIImage imageWithContentsOfFile:pathForFile];
            if (completionHandler) {
                completionHandler(image, nil);
            }
        });
        return [self.mediaID intValue];
    }
    // TODO: fetch image from server, for now just exit with missing image
    if (completionHandler) {
        completionHandler(nil, nil);
    }
    return [self.mediaID intValue];
}

- (void)cancelImageRequest:(WPMediaRequestID)requestID
{

}

- (WPMediaType)assetType
{
    if (self.mediaType == MediaTypeImage){
        return WPMediaTypeImage;
    } else if (self.mediaType == MediaTypeVideo) {
        return WPMediaTypeVideo;
    } else {
        return WPMediaTypeOther;
    }
}

- (NSTimeInterval)duration
{
    if (self.mediaType != MediaTypeVideo){
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