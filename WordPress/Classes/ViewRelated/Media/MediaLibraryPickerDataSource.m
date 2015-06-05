#import "MediaLibraryPickerDataSource.h"
#import "Media.h"
#import "MediaService.h"

@interface  MediaLibraryPickerDataSource()
@property (nonatomic, strong) id<WPMediaGroup> mediaGroup;
@end

@implementation MediaLibraryPickerDataSource

- (instancetype)init
{
    self = [super init];
    if (self) {
        _mediaGroup = [[MediaLibraryGroup alloc] init];
    }
    return self;
}

-(NSInteger)numberOfAssets
{
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
    return nil;
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
