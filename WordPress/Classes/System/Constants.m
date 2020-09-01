#import "Constants.h"


/// XMLRPC Constants
///
NSString *const WPComXMLRPCUrl                                      = @"https://wordpress.com/xmlrpc.php";
NSString *const WPComDefaultAccountUrlKey                           = @"AccountDefaultDotcom";

/// WordPress URL's
///
NSString *const WPMobileReaderURL                                   = @"https://en.wordpress.com/reader/mobile/v2/?chrome=no";
NSString *const WPMobileReaderDetailURL                             = @"https://en.wordpress.com/reader/mobile/v2/?template=details";
NSString *const WPAutomatticMainURL                                 = @"https://beau.voyage/";
NSString *const WPAutomatticTermsOfServiceURL                       = @"https://beau.voyage/terms-conditions/";
NSString *const WPAutomatticPrivacyURL                              = @"https://beau.voyage/privacy-policy/";
NSString *const WPAutomatticCookiesURL                              = @"https://automattic.com/cookies/";
NSString *const WPAutomatticAppsBlogURL                             = @"https://blog.beau.voyage";
NSString *const WPGithubMainURL                                     = @"https://github.com/beaubateau/beauVoyage-iOS/";
NSString *const WPComReferrerURL                                    = @"https://beau.voyage";
NSString *const AutomatticDomain                                    = @"beau.voyage";
NSString *const WPComDomain                                         = @"beau.voyage";

/// Notifications Constants
///
#ifdef DEBUG
NSString *const  WPPushNotificationAppId                            = @"voyage.beau.appstore.dev";
#else
#ifdef INTERNAL_BUILD
NSString *const   WPPushNotificationAppId                           = @"voyage.beau.internal";
#else
NSString *const WPPushNotificationAppId                             = @"voyage.beau.appstore";
#endif
#endif
/// Keychain Constants
///
#ifdef INTERNAL_BUILD
NSString *const WPAppGroupName                                      = @"group.voyage.beau.internal";
NSString *const WPAppKeychainAccessGroup                            = @"99KV9Z6BKV.voyage.beau.internal";
#else
NSString *const WPAppGroupName                                      = @"group.voyage.beau";
NSString *const WPAppKeychainAccessGroup                            = @"C7B8L9KZV4.group.voyage.beau";
#endif

/// Notification Content Extension Constants
///
NSString *const WPNotificationContentExtensionKeychainServiceName   = @"NotificationContentExtension";
NSString *const WPNotificationContentExtensionKeychainTokenKey      = @"OAuth2Token";
NSString *const WPNotificationContentExtensionKeychainUsernameKey   = @"Username";

/// Notification Service Extension Constants
///
NSString *const WPNotificationServiceExtensionKeychainServiceName   = @"NotificationServiceExtension";
NSString *const WPNotificationServiceExtensionKeychainTokenKey      = @"OAuth2Token";
NSString *const WPNotificationServiceExtensionKeychainUsernameKey   = @"Username";

/// Share Extension Constants
///
NSString *const WPShareExtensionKeychainUsernameKey                 = @"Username";
NSString *const WPShareExtensionKeychainTokenKey                    = @"OAuth2Token";
NSString *const WPShareExtensionKeychainServiceName                 = @"ShareExtension";
NSString *const WPShareExtensionUserDefaultsPrimarySiteName         = @"WPShareUserDefaultsPrimarySiteName";
NSString *const WPShareExtensionUserDefaultsPrimarySiteID           = @"WPShareUserDefaultsPrimarySiteID";
NSString *const WPShareExtensionUserDefaultsLastUsedSiteName        = @"WPShareUserDefaultsLastUsedSiteName";
NSString *const WPShareExtensionUserDefaultsLastUsedSiteID          = @"WPShareUserDefaultsLastUsedSiteID";
NSString *const WPShareExtensionMaximumMediaDimensionKey            = @"WPShareExtensionMaximumMediaDimensionKey";
NSString *const WPShareExtensionRecentSitesKey                      = @"WPShareExtensionRecentSitesKey";

/// Today Widget Constants
///
NSString *const WPStatsTodayWidgetKeychainTokenKey                  = @"OAuth2Token";
NSString *const WPStatsTodayWidgetKeychainServiceName               = @"TodayWidget";
NSString *const WPStatsTodayWidgetUserDefaultsSiteIdKey             = @"WordPressTodayWidgetSiteId";
NSString *const WPStatsTodayWidgetUserDefaultsSiteNameKey           = @"WordPressTodayWidgetSiteName";
NSString *const WPStatsTodayWidgetUserDefaultsSiteUrlKey            = @"WordPressTodayWidgetSiteUrl";
NSString *const WPStatsTodayWidgetUserDefaultsSiteTimeZoneKey       = @"WordPressTodayWidgetTimeZone";

/// Apple ID Constants
///
NSString *const WPAppleIDKeychainUsernameKey                        = @"Username";
NSString *const WPAppleIDKeychainServiceName                        = @"AppleID";

/// iTunes Constants
///
NSString *const WPiTunesAppId                                       = @"1517718114";

/// Scheme Constants
///
NSString *const WPComScheme                                         = WPCOM_SCHEME;
