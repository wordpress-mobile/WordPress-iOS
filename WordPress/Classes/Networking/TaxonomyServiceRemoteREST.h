#import <Foundation/Foundation.h>
#import "TaxonomyServiceRemote.h"
#import "SiteServiceRemoteREST.h"

extern NSString * const TaxonomyRESTCategoryIdentifier;
extern NSString * const TaxonomyRESTTagIdentifier;

extern NSString * const TaxonomyRESTIDParameter;
extern NSString * const TaxonomyRESTNameParameter;
extern NSString * const TaxonomyRESTSlugParameter;
extern NSString * const TaxonomyRESTParentParameter;
extern NSString * const TaxonomyRESTSearchParameter;
extern NSString * const TaxonomyRESTOrderParameter;
extern NSString * const TaxonomyRESTOrderByParameter;
extern NSString * const TaxonomyRESTNumberParameter;
extern NSString * const TaxonomyRESTOffsetParameter;
extern NSString * const TaxonomyRESTPageParameter;

@interface TaxonomyServiceRemoteREST : SiteServiceRemoteREST <TaxonomyServiceRemote>

@end
