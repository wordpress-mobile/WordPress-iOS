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
NSString *const WPAutomatticAppsBlogURL                             = @"https://apps.wordpress.com/blog/";
NSString *const WPGithubMainURL                                     = @"https://github.com/wordpress-mobile/WordPress-iOS/";
NSString *const WPTwitterWordPressHandle                            = @"@WordPressiOS";
NSString *const WPTwitterWordPressMobileURL                         = @"https://twitter.com/WordPressiOS";

/// Notifications Constants
///
#ifdef DEBUG
NSString *const  WPPushNotificationAppId                            = @"org.wordpress.appstore.dev";
#else
#ifdef INTERNAL_BUILD
NSString *const   WPPushNotificationAppId                           = @"org.wordpress.internal";
#else
NSString *const WPPushNotificationAppId                             = @"org.wordpress.appstore";
#endif
#endif
/// Keychain Constants
///
#ifdef INTERNAL_BUILD
NSString *const WPAppGroupName                                      = @"group.org.wordpress.internal";
NSString *const WPAppKeychainAccessGroup                            = @"99KV9Z6BKV.org.wordpress.internal";
#else
NSString *const WPAppGroupName                                      = @"group.org.wordpress";
NSString *const WPAppKeychainAccessGroup                            = @"3TMU3BH3NK.org.wordpress";
#endif

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

/// Today Widget Constants
///
NSString *const WPStatsTodayWidgetKeychainTokenKey                  = @"OAuth2Token";
NSString *const WPStatsTodayWidgetKeychainServiceName               = @"TodayWidget";
NSString *const WPStatsTodayWidgetUserDefaultsSiteIdKey             = @"WordPressTodayWidgetSiteId";
NSString *const WPStatsTodayWidgetUserDefaultsSiteNameKey           = @"WordPressTodayWidgetSiteName";
NSString *const WPStatsTodayWidgetUserDefaultsSiteTimeZoneKey       = @"WordPressTodayWidgetTimeZone";
NSString *const WPStatsTodayWidgetUserDefaultsViewCountKey          = @"TodayViewCount";
NSString *const WPStatsTodayWidgetUserDefaultsVisitorCountKey       = @"TodayVisitorCount";

/// iTunes Constants
///
NSString *const WPiTunesAppId                                       = @"335703880";

/// Scheme Constants
///
NSString *const WPComScheme                                         = WPCOM_SCHEME;
