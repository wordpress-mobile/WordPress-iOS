#import <Foundation/Foundation.h>
#import "WordPressComRESTAPIInterfacing.h"
#import "WordPressComRESTAPIVersion.h"

NS_ASSUME_NONNULL_BEGIN

/**
 *  @class  ServiceRemoteREST
 *  @brief  Parent class for all REST service classes.
 */
@interface ServiceRemoteWordPressComREST : NSObject

/**
 *  @brief      The interface to the WordPress.com API to use for performing REST requests.
 *              This is meant to gradually replace `wordPressComRestApi`.
 */
@property (nonatomic, strong, readonly) id<WordPressComRESTAPIInterfacing> wordPressComRESTAPI;

/**
 *  @brief      Designated initializer.
 *
 *  @param      api     The API to use for communication.  Cannot be nil.
 *
 *  @returns    The initialized object.
 */
- (instancetype)initWithWordPressComRestApi:(id<WordPressComRESTAPIInterfacing>)api;

#pragma mark - Request URL construction

/**
 *  @brief      Constructs the request URL for the specified API version and specified resource URL.
 *
 *  @param      endpoint        The URL of the resource for the request.  Cannot be nil.
 *  @param      apiVersion      The version of the API to use.
 *
 *  @returns    The request URL.
 */
- (NSString *)pathForEndpoint:(NSString *)endpoint
                  withVersion:(WordPressComRESTAPIVersion)apiVersion
NS_SWIFT_NAME(path(forEndpoint:withVersion:));

@end

NS_ASSUME_NONNULL_END
