#import <Foundation/Foundation.h>
#import "TaxonomyServiceRemote.h"
#import "ServiceRemoteWordPressXMLRPC.h"

@class RemoteCategory;

@interface TaxonomyServiceRemoteXMLRPC : ServiceRemoteWordPressXMLRPC<TaxonomyServiceRemote>

- (void)getTagWithId:(nonnull NSNumber *)tagId
             success:(nullable void (^)(RemotePostTag * _Nonnull tag))success
             failure:(nullable void (^)(NSError * _Nonnull error))failure;

@end
