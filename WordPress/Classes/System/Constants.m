#import "Constants.h"

NSString *const WPMobileReaderURL                                   = @"https://en.wordpress.com/reader/mobile/v2/?chrome=no";
NSString *const WPMobileReaderDetailURL                             = @"https://en.wordpress.com/reader/mobile/v2/?template=details";
NSString *const WPMobileReaderFFURL                                 = @"https://en.wordpress.com/reader/mobile/v2/?template=friendfinder";

NSString *const WPComXMLRPCUrl                                      = @"https://wordpress.com/xmlrpc.php";
NSString *const WPComDefaultAccountUrlKey                           = @"AccountDefaultDotcom";
NSString *const WPComDefaultAccountUsernameKey                      = @"wpcom_username_preference";

NSString *const WPNotificationsBucketName                           = @"note20";
NSString *const WPNotificationsJetpackInformationURL                = @"http://jetpack.me/about/";

#ifdef INTERNAL_BUILD
NSString *const WPAppGroupName                                      = @"group.org.wordpress.internal";
NSString *const WPStatsTodayWidgetOAuth2TokenKeychainAccessGroup    = @"99KV9Z6BKV.org.wordpress.internal";
#else
NSString *const WPAppGroupName                                      = @"group.org.wordpress";
NSString *const WPStatsTodayWidgetOAuth2TokenKeychainAccessGroup    = @"3TMU3BH3NK.org.wordpress";
#endif

NSString *const WPStatsTodayWidgetOAuth2TokenKeychainUsername       = @"OAuth2Token";
NSString *const WPStatsTodayWidgetOAuth2TokenKeychainServiceName    = @"TodayWidget";
NSString *const WPStatsTodayWidgetUserDefaultsSiteIdKey             = @"WordPressTodayWidgetSiteId";
NSString *const WPStatsTodayWidgetUserDefaultsSiteNameKey           = @"WordPressTodayWidgetSiteName";
NSString *const WPStatsTodayWidgetUserDefaultsSiteTimeZoneKey       = @"WordPressTodayWidgetTimeZone";
NSString *const WPStatsTodayWidgetUserDefaultsViewCountKey          = @"TodayViewCount";
NSString *const WPStatsTodayWidgetUserDefaultsVisitorCountKey       = @"TodayVisitorCount";

NSString *const WPInternalBetaShakeToPullUpFeedbackKey              = @"InternalBetaShakeToPullUpFeedback";

#if defined(INTERNAL_BUILD) || defined(DEBUG)
BOOL const WPJetpackRESTEnabled                                     = YES;
#else
BOOL const WPJetpackRESTEnabled                                     = NO;
#endif

NSString *const WPiTunesAppId                                       = @"335703880";
