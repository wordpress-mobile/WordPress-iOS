#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, ServiceRemoteWordPressComRESTApiVersion)
{
    ServiceRemoteWordPressComRESTApiNoVersion   = 0000,
    ServiceRemoteWordPressComRESTApiVersion_1_1 = 1001,
    ServiceRemoteWordPressComRESTApiVersion_1_2 = 1002,
    ServiceRemoteWordPressComRESTApiVersion_1_3 = 1003,
};

@class WordPressComRestApi;

/**
 *  @class  ServiceRemoteREST
 *  @brief  Parent class for all REST service classes.
 */
@interface ServiceRemoteWordPressComREST : NSObject


/**
 *  @brief      The API object to use for communications.
 */
@property (nonatomic, strong, readonly) WordPressComRestApi *wordPressComRestApi;

/**
 *  @brief      Designated initializer.
 *
 *  @param      api     The API to use for communication.  Cannot be nil.
 *
 *  @returns    The initialized object.
 */
- (id)initWithWordPressComRestApi:(WordPressComRestApi *)api;

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
                  withVersion:(ServiceRemoteWordPressComRESTApiVersion)apiVersion;

/**
 *  @brief      An anonoymous API object to use for communications where authentication is not needed.
 *
 *  @param      userAgent       The user agent string to use on all requests
 */
+ (WordPressComRestApi *)anonymousWordPressComRestApiWithUserAgent:(NSString *)userAgent;


@end
