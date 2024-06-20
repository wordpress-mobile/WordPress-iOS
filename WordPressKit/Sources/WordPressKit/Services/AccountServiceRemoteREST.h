#import <Foundation/Foundation.h>
#import <WordPressKit/AccountServiceRemote.h>
#import <WordPressKit/ServiceRemoteWordPressComREST.h>

typedef NSString* const MagicLinkParameter NS_TYPED_ENUM;
extern MagicLinkParameter const MagicLinkParameterFlow;
extern MagicLinkParameter const MagicLinkParameterSource;

typedef NSString* const MagicLinkSource NS_TYPED_ENUM;
extern MagicLinkSource const MagicLinkSourceDefault;
extern MagicLinkSource const MagicLinkSourceJetpackConnect;

//typedef NSString* const MagicLinkFlow NS_TYPED_ENUM;
typedef NSString* const MagicLinkFlow NS_STRING_ENUM;
extern MagicLinkFlow const MagicLinkFlowLogin;
extern MagicLinkFlow const MagicLinkFlowSignup;

@interface AccountServiceRemoteREST : ServiceRemoteWordPressComREST <AccountServiceRemote>

/**
*  @brief      Request an authentication link be sent to the email address provided.
*
 *  @param      success     The block that will be executed on success.  Can be nil.
 *  @param      failure     The block that will be executed on failure.  Can be nil.
 */
- (void)requestWPComAuthLinkForEmail:(NSString *)email
                            clientID:(NSString *)clientID
                        clientSecret:(NSString *)clientSecret
                              source:(MagicLinkSource)source
                         wpcomScheme:(NSString *)scheme
                             success:(void (^)(void))success
                             failure:(void (^)(NSError *error))failure;

/**
 *  @brief      Request a signup link be sent to the email address provided.
 *
 *  @param      success     The block that will be executed on success.  Can be nil.
 *  @param      failure     The block that will be executed on failure.  Can be nil.
 */
- (void)requestWPComSignupLinkForEmail:(NSString *)email
                              clientID:(NSString *)clientID
                          clientSecret:(NSString *)clientSecret
                           wpcomScheme:(NSString *)scheme
                               success:(void (^)(void))success
                               failure:(void (^)(NSError *error))failure;

@end
