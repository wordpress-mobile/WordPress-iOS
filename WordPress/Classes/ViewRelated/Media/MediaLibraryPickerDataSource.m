#import "MediaLibraryPickerDataSource.h"
#import "Media.h"
#import "MediaService.h"
#import "Blog.h"
#import "ContextManager.h"

@interface  MediaLibraryPickerDataSource()

@property (nonatomic, strong) id<WPMediaGroup> mediaGroup;
@property (nonatomic, strong) Blog *blog;
@property (nonatomic, assign) WPMediaType filter;
@property (nonatomic, strong) NSArray *media;

@end

@implementation MediaLibraryPickerDataSource

- (instancetype)initWithBlog:(Blog *)blog 
{
    self = [super init];
    if (self) {
        _mediaGroup = [[MediaLibraryGroup alloc] init];
        _blog = blog;
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

- (id<WPMediaGroup>)groupAtIndex:(NSInteger)index {
    return self.mediaGroup;
}

-(void)loadDataWithSuccess:(WPMediaChangesBlock)successBlock failure:(WPMediaFailureBlock)failureBlock
{
    NSString *entityName = NSStringFromClass([Media class]);
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:entityName];
    switch (self.filter){
        case WPMediaTypeImage:{
            request.predicate = [NSPredicate predicateWithFormat:@"mediaTypeString = %@", @"image"];
        }break;
        case WPMediaTypeVideo:{
            request.predicate = [NSPredicate predicateWithFormat:@"mediaTypeString = %@", @"video"];
        }break;
        case WPMediaTypeAll:{
            request.predicate = [NSPredicate predicateWithFormat:@"mediaTypeString = %@ || mediaTypeString = %@", @"image", @"video"];
        }break;
        default:
            break;
    };
    NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"creationDate" ascending:YES];
    request.sortDescriptors = @[sortDescriptor];
    NSError *error;
    self.media = [[[ContextManager sharedInstance] mainContext] executeFetchRequest:request error:&error];
    if (self.media == nil && error){
        DDLogVerbose(@"Error fecthing media: %@", [error localizedDescription]);
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

}

-(void)addVideoFromURL:(NSURL *)url completionBlock:(WPMediaAddedBlock)completionBlock
{

}

-(void)setMediaTypeFilter:(WPMediaType)filter
{
    self.filter = filter;
}

-(WPMediaType)mediaTypeFilter
{
    return self.filter;
}

-(id<WPMediaAsset>)mediaAtIndex:(NSInteger)index
{
    return self.media[index];
}

@end

@implementation MediaLibraryGroup

- (id)baseGroup {
    return self;
}

- (NSString *)name {
    return NSLocalizedString(@"Media Library", @"Name for the WordPress Media Library");
}

- (WPMediaRequestID)imageWithSize:(CGSize)size completionHandler:(WPMediaImageBlock)completionHandler
{
    if (completionHandler){
        completionHandler(nil, nil);
    }
    return 0;
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
    return 0;
}

@end

@implementation Media(WPMediaAsset)

- (WPMediaRequestID)imageWithSize:(CGSize)size completionHandler:(WPMediaImageBlock)completionHandler
{
    if (self.absoluteLocalURL) {
        UIImage *image = [UIImage imageWithContentsOfFile:self.absoluteLocalURL];
        if (completionHandler) {
            completionHandler(image, nil);
        }
        return 0;
    }
    // TODO: fetch image from server
    if (completionHandler) {
        completionHandler(nil, nil);
    }
    return 0;
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
    return [self.length doubleValue];
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