#import <Foundation/Foundation.h>

typedef enum
{
    ServiceRemoteRESTApiVersion_1_1 = 1001,
    ServiceRemoteRESTApiVersion_1_2 = 1002,
} ServiceRemoteRESTApiVersion;

@class WordPressComApi;

/**
 *  @class  ServiceRemoteREST
 *  @brief  Parent class for all REST service classes.
 */
@interface ServiceRemoteREST : NSObject

/**
 *  @brief      The API object to use for communications.
 */
@property (nonatomic, strong, readonly) WordPressComApi *api;

/**
 *  @brief      Designated initializer.
 *
 *  @param      api     The API to use for communitcation.  Cannot be nil.
 *
 *  @returns    The initialized object.
 */
- (id)initWithApi:(WordPressComApi *)api;

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
                  withVersion:(ServiceRemoteRESTApiVersion)apiVersion;

@end
