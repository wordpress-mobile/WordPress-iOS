#import "Constants.h"


/// XMLRPC Constants
///
NSString *const WPComXMLRPCUrl                                      = @"https://wordpress.com/xmlrpc.php";
NSString *const WPComDefaultAccountUrlKey                           = @"AccountDefaultDotcom";

/// WordPress URL's
///
NSString *const WPMobileReaderURL                                   = @"https://en.wordpress.com/reader/mobile/v2/?chrome=no";
NSString *const WPMobileReaderDetailURL                             = @"https://en.wordpress.com/reader/mobile/v2/?template=details";
NSString *const WPAutomatticMainURL                                 = @"https://automattic.com/";
NSString *const WPAutomatticTermsOfServiceURL                       = @"https://wordpress.com/tos/";
NSString *const WPAutomatticPrivacyURL                              = @"https://automattic.com/privacy/";
NSString *const WPAutomatticCCPAPrivacyNoticeURL                    = @"https://automattic.com/privacy/#california-consumer-privacy-act-ccpa";
NSString *const WPAutomatticCookiesURL                              = @"https://automattic.com/cookies/";
NSString *const WPGithubMainURL                                     = @"https://github.com/wordpress-mobile/WordPress-iOS/";
NSString *const WPComReferrerURL                                    = @"https://wordpress.com";
NSString *const AutomatticDomain                                    = @"automattic.com";
NSString *const WPComDomain                                         = @"wordpress.com";

/// Keychain Constants
///
#ifdef INTERNAL_BUILD
NSString *const WPAppGroupName                                      = @"group.org.wordpress.internal";
NSString *const WPAppKeychainAccessGroup                            = @"99KV9Z6BKV.org.wordpress.internal";
#else
#if ALPHA_BUILD
NSString *const WPAppGroupName                                      = @"group.org.wordpress.alpha";
NSString *const WPAppKeychainAccessGroup                            = @"99KV9Z6BKV.org.wordpress.alpha";
#else
NSString *const WPAppGroupName                                      = @"group.org.wordpress";
NSString *const WPAppKeychainAccessGroup                            = @"3TMU3BH3NK.org.wordpress";
#endif
#endif

/// Notification Content Extension Constants
///
NSString *const WPNotificationContentExtensionKeychainServiceName   = @"NotificationContentExtension";
NSString *const WPNotificationContentExtensionKeychainTokenKey      = @"OAuth2Token";
NSString *const WPNotificationContentExtensionKeychainUsernameKey   = @"Username";

/// Apple ID Constants
///
NSString *const WPAppleIDKeychainUsernameKey                        = @"Username";
NSString *const WPAppleIDKeychainServiceName                        = @"AppleID";

/// iTunes Constants
///
NSString *const WPiTunesAppId                                       = @"335703880";

/// Scheme Constants
///
NSString *const WPComScheme                                         = WPCOM_SCHEME;
