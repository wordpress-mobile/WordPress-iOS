#import "MediaLibraryPickerDataSource.h"
#import "Media.h"
#import "MediaService.h"
#import "Blog.h"

@interface  MediaLibraryPickerDataSource()

@property (nonatomic, strong) id<WPMediaGroup> mediaGroup;
@property (nonatomic, strong) Blog *blog;

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
    return [self.blog.media count];
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

}

-(WPMediaType)mediaTypeFilter
{
    return WPMediaTypeAll;
}

-(id<WPMediaAsset>)mediaAtIndex:(NSInteger)index
{
    return [self.blog.media allObjects][index];
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
    if (self.localURL) {
        UIImage *image = [UIImage imageWithContentsOfFile:self.localURL];
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