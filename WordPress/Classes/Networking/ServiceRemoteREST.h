#import <Foundation/Foundation.h>

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
 *  @param      apiVersion      The version of the API to use.  Cannot be nil.
 *  @param      resourceUrl     The URL of the resource for the request.  Cannot be nil.
 *
 *  @returns    The request URL.
 */
- (NSString *)requestUrlForApiVersion:(NSString *)apiVersion
                          resourceUrl:(NSString *)resourceUrl;

/**
 *  @brief      Constructs the request URL for the default API version and specified resource URL.
 *
 *  @param      resourceUrl     The URL of the resource for the request.  Cannot be nil.
 *
 *  @returns    The request URL.
 */
- (NSString *)requestUrlForDefaultApiVersionAndResourceUrl:(NSString *)resourceUrl;

@end
