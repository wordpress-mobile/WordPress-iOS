#import <Foundation/Foundation.h>

/**
 *  @brief      The user defaults key to store the shake-to-pull setting for Lookback.
 */
extern NSString* const WPLookbackPresenterShakeToPullUpFeedbackKey;

/**
 *  @class      WPLookbackPresenter
 *  @brief      Presents lookback when the shake gesture is identified.
 *  @details    
 */
@interface WPLookbackPresenter : NSObject

/**
 *  @brief      Initializes the object to use the specified key window for the shake gesture
 *              recognizer.
 *
 *  @param      token       The token to use to initialize lookback.  Cannot be an empty string and
 *                          cannot be nil.
 *  @param      userId      The identifier that lookback will use for the user.  Can be nil or empty
 *                          since the user may not be logged in yet.
 *  @param      window      The window to add the shake gesture recognizer to.  Cannot be nil.
 *
 *  @returns    The initialized object.
 */
- (instancetype)initWithToken:(NSString *)token
                       userId:(NSString *)userId
                       window:(UIWindow *)window;

@end
