#import <Foundation/Foundation.h>


/**
 *  @class           RemoteBlog
 *  @brief           This class encapsulates all of the *remote* Blog properties
 */

@interface RemoteBlog : NSObject

/**
 *  @details The ID of the Blog entity.
 */
@property (nonatomic, copy) NSNumber *blogID;

/**
 *  @details Represents the Blog Name.
 */
@property (nonatomic, copy) NSString *name;

/**
 *  @details Description of the WordPress Blog.
 */
@property (nonatomic, copy) NSString *tagline;

/**
 *  @details Represents the Blog Name.
 */
@property (nonatomic, copy) NSString *url;

/**
 *  @details Maps to the XMLRPC endpoint.
 */
@property (nonatomic, copy) NSString *xmlrpc;

/**
 *  @details Site Icon's URL.
 */
@property (nonatomic, copy) NSString *icon;

/**
 *  @details Product ID of the site's current plan, if it has one.
 */
@property (nonatomic, copy) NSNumber *planID;

/**
 *  @details Indicates whether it's a jetpack site, or not.
 */
@property (nonatomic, assign) BOOL jetpack;

/**
 *  @details Boolean indicating whether the current user has Admin privileges, or not.
 */
@property (nonatomic, assign) BOOL isAdmin;

/**
 *  @details Blog's visibility preferences.
 */
@property (nonatomic, assign) BOOL visible;

/**
 *  @details Blog's options preferences.
 */
@property (nonatomic, strong) NSDictionary *options;

@end
