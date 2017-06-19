#import <Foundation/Foundation.h>
#import "BlogServiceRemote.h"
@import WordPressKit;

typedef void (^OptionsHandler)(NSDictionary *options);

@interface BlogServiceRemoteXMLRPC : ServiceRemoteWordPressXMLRPC<BlogServiceRemote>

/**
 *  @brief      Synchronizes a blog's options.
 *
 *  @note       Available in XML-RPC only.
 *
 *  @param      success     The block that will be executed on success.  Can be nil.
 *  @param      failure     The block that will be executed on failure.  Can be nil.
 */
- (void)syncBlogOptionsWithSuccess:(OptionsHandler)success
                           failure:(void (^)(NSError *error))failure;

/**
 *  @brief      Update a blog's options.
 *
 *  @note       Available in XML-RPC only.
 *
 *  @param      success     The block that will be executed on success.  Can be nil.
 *  @param      failure     The block that will be executed on failure.  Can be nil.
 */
- (void)updateBlogOptionsWith:(NSDictionary *)remoteBlogOptions
                      success:(SuccessHandler)success
                      failure:(void (^)(NSError *error))failure;

@end
