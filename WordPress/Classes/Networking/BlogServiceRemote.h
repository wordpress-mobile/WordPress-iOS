#import <Foundation/Foundation.h>

@class RemoteBlog;
@class RemoteBlogSettings;
@class RemotePostType;

typedef void (^PostTypesHandler)(NSArray <RemotePostType *> *postTypes);
typedef void (^PostFormatsHandler)(NSDictionary *postFormats);
typedef void (^MultiAuthorCheckHandler)(BOOL isMultiAuthor);
typedef void (^SuccessHandler)();

@protocol BlogServiceRemote <NSObject>

/**
 *  @brief      Checks if a blog has multiple authors.
 *
 *  @param      success     The block that will be executed on success.  Can be nil.
 *  @param      failure     The block that will be executed on failure.  Can be nil.
 */
- (void)checkMultiAuthorWithSuccess:(MultiAuthorCheckHandler)success
                            failure:(void (^)(NSError *error))failure;

/**
 *  @brief      Synchronizes a blog's post types.
 *
 *  @param      success     The block that will be executed on success.  Can be nil.
 *  @param      failure     The block that will be executed on failure.  Can be nil.
 */
- (void)syncPostTypesWithSuccess:(PostTypesHandler)success
                         failure:(void (^)(NSError *error))failure;

/**
 *  @brief      Synchronizes a blog's post formats.
 *
 *  @param      success     The block that will be executed on success.  Can be nil.
 *  @param      failure     The block that will be executed on failure.  Can be nil.
 */
- (void)syncPostFormatsWithSuccess:(PostFormatsHandler)success
                           failure:(void (^)(NSError *error))failure;

@end
