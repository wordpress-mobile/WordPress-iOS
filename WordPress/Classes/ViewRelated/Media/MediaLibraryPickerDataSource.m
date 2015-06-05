#import "MediaLibraryPickerDataSource.h"
#import "Media.h"
#import "MediaService.h"

@implementation MediaLibraryPickerDataSource

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
   return nil;
}

- (id<WPMediaGroup>)groupAtIndex:(NSInteger)index {
    return nil;
}

-(void)loadDataWithSuccess:(WPMediaChangesBlock)successBlock failure:(WPMediaFailureBlock)failureBlock
{
    
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
