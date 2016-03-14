#import "Constants.h"

NSString *const WPMobileReaderURL                                   = @"https://en.wordpress.com/reader/mobile/v2/?chrome=no";
NSString *const WPMobileReaderDetailURL                             = @"https://en.wordpress.com/reader/mobile/v2/?template=details";

NSString *const WPComXMLRPCUrl                                      = @"https://wordpress.com/xmlrpc.php";
NSString *const WPComDefaultAccountUrlKey                           = @"AccountDefaultDotcom";

NSString *const WPJetpackInformationURL                             = @"https://jetpack.me/about/";
NSString *const WPAutomatticMainURL                                 = @"https://automattic.com/";
NSString *const WPAutomatticTermsOfServiceURL                       = @"https://wordpress.com/tos/";
NSString *const WPAutomatticPrivacyURL                              = @"https://automattic.com/privacy/";
NSString *const WPAutomatticAppsBlogURL                             = @"https://apps.wordpress.org/blog/";
NSString *const WPGithubMainURL                                     = @"https://github.com/wordpress-mobile/WordPress-iOS/";
NSString *const WPTwitterWordPressHandle                            = @"@WordPressiOS";
NSString *const WPTwitterWordPressMobileURL                         = @"https://twitter.com/WordPressiOS";

NSString *const WPBlavatarBaseURL                                   = @"http://gravatar.com/blavatar";
NSString *const WPGravatarBaseURL                                   = @"http://gravatar.com/avatar";

NSString *const WPNotificationsBucketName                           = @"note20";

#ifdef INTERNAL_BUILD
NSString *const WPAppOAuth2TokenKeychainAccessGroup                 = @"99KV9Z6BKV.org.wordpress.internal";
NSString *const WPAppDefaultsGroupName                              = @"group.org.wordpress.internal";
#else
NSString *const WPAppOAuth2TokenKeychainAccessGroup                 = @"3TMU3BH3NK.org.wordpress";
NSString *const WPAppDefaultsGroupName                              = @"group.org.wordpress";
#endif

// Note: Since we're adding a new Sharing Extension (Feb.23.2016), the former Today Widget constants are being reused.
NSString *const WPAppOAuth2TokenKeychainUsername                    = @"OAuth2Token";
NSString *const WPAppOAuth2TokenKeychainServiceName                 = @"TodayWidget";

NSString *const WPShareUserDefaultsPrimarySiteName                  = @"WPShareUserDefaultsPrimarySiteName";
NSString *const WPShareUserDefaultsPrimarySiteID                    = @"WPShareUserDefaultsPrimarySiteID";

NSString *const WPStatsTodayWidgetUserDefaultsSiteIdKey             = @"WordPressTodayWidgetSiteId";
NSString *const WPStatsTodayWidgetUserDefaultsSiteNameKey           = @"WordPressTodayWidgetSiteName";
NSString *const WPStatsTodayWidgetUserDefaultsSiteTimeZoneKey       = @"WordPressTodayWidgetTimeZone";
NSString *const WPStatsTodayWidgetUserDefaultsViewCountKey          = @"TodayViewCount";
NSString *const WPStatsTodayWidgetUserDefaultsVisitorCountKey       = @"TodayVisitorCount";

NSString *const WPiTunesAppId                                       = @"335703880";

NSString *const WPOnePasswordWordPressTitle                         = @"WordPress";
NSString *const WPOnePasswordWordPressComURL                        = @"wordpress.com";
NSInteger const WPOnePasswordGeneratedMinLength                     = 7;
NSInteger const WPOnePasswordGeneratedMaxLength                     = 50;

NSString *const WPComScheme = WPCOM_SCHEME;
