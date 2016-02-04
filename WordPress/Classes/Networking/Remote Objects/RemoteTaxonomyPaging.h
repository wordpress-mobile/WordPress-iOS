#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, RemoteTaxonomyPagingResultsOrder) {
    RemoteTaxonomyPagingOrderAscending = 0,
    RemoteTaxonomyPagingOrderDescending
};

typedef NS_ENUM(NSUInteger, RemoteTaxonomyPagingResultsOrdering) {
    /* Order the results by the name of the taxonomy.
     */
    RemoteTaxonomyPagingResultsOrderingByName = 0,
    /* Order the results by the number of posts associated with the taxonomy.
     */
    RemoteTaxonomyPagingResultsOrderingByCount
};


/**
   @class RemoteTaxonomyPaging
   @brief A paging object for passing parameters to the API when requesting paged lists of taxonomies.
          See each remote API for specifics regarding default values and limits.
          WP.com/REST Jetpack: https://developer.wordpress.com/docs/api/1.1/get/sites/%24site/categories/
          XML-RPC: https://codex.wordpress.org/XML-RPC_WordPress_API/Taxonomies
 */
@interface RemoteTaxonomyPaging : NSObject

/**
 @brief The max number of taxonomies to return.
 */
@property (nonatomic, strong) NSNumber *number;

/**
  @brief 0-indexed offset for paging.
 */
@property (nonatomic, strong) NSNumber *offset;

/**
  @brief Return the Nth 1-indexed page of tags. Takes precedence over the offset parameter.
  @attention Not supported in XML-RPC.
 */
@property (nonatomic, strong) NSNumber *page;

/**
  @brief Return the taxonomies in ascending or descending order. Defaults YES via the API.
 */
@property (nonatomic, assign) RemoteTaxonomyPagingResultsOrder order;

/**
  @brief Return the taxonomies ordering by name or associated count.
 */
@property (nonatomic, assign) RemoteTaxonomyPagingResultsOrdering orderBy;

@end
