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

@end
