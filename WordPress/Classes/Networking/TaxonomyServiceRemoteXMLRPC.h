#import <Foundation/Foundation.h>
#import "TaxonomyServiceRemote.h"
#import "ServiceRemoteXMLRPC.h"

extern NSString * const TaxonomyXMLRPCCategoryIdentifier;
extern NSString * const TaxonomyXMLRPCTagIdentifier;

extern NSString * const TaxonomyXMLRPCIDParameter;
extern NSString * const TaxonomyXMLRPCSlugParameter;
extern NSString * const TaxonomyXMLRPCNameParameter;
extern NSString * const TaxonomyXMLRPCParentParameter;
extern NSString * const TaxonomyXMLRPCSearchParameter;
extern NSString * const TaxonomyXMLRPCOrderParameter;
extern NSString * const TaxonomyXMLRPCOrderByParameter;
extern NSString * const TaxonomyXMLRPCNumberParameter;
extern NSString * const TaxonomyXMLRPCOffsetParameter;

@class RemoteCategory;

@interface TaxonomyServiceRemoteXMLRPC : ServiceRemoteXMLRPC<TaxonomyServiceRemote>

@end
