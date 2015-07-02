#import <Foundation/Foundation.h>

/**
 *  @class      WPThemeSettings
 *  @brief      Small temporary utility class to let the caller turn the themes feature ON and OFF.
 *  @details    Since this feature is a work in progress, it will be hidden by default and will
 *              require that the user enabled it through a hidden URL in their mobile safari app.
 */
@interface WPThemeSettings : NSObject

#pragma mark - URL handling

/**
 *  @brief      Call this method to handle a URL.
 *  @details    Make sure you check the URL against shouldHandleURL first.
 *
 *  @param      url     The url to handle.  Cannot be nil.
 *
 *  @returns    YES if this method can handle the URL for any reason.  NO otherwise.
 */
+ (BOOL)handleURL:(NSURL *)url;

/**
 *  @brief      Call this method to figure out if a URL is meant to be handled by this class.
 *
 *  @param      url     The url to check.  Cannot be nil.
 *
 *  @returns    YES if this class should handle the URL.  If that's the case you can call handleURL.
 *              Otherwise NO is returned.
 */
+ (BOOL)shouldHandleURL:(NSURL *)url;

#pragma mark - Enabling and disabling

/**
 *  @brief      Call this method to know if the themes feature is enabled.
 *
 *  @returns    YES if the feature is enabled, NO otherwise.
 */
+ (BOOL)isEnabled;

@end
