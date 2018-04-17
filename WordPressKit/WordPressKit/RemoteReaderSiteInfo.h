#import <Foundation/Foundation.h>


@class RemoteReaderSiteInfoSubscriptionEmail;
@class RemoteReaderSiteInfoSubscriptionPost;


@interface RemoteReaderSiteInfo: NSObject
@property (nonatomic, strong) NSNumber *feedID;
@property (nonatomic, strong) NSString *feedURL;
@property (nonatomic) BOOL isFollowing;
@property (nonatomic) BOOL isJetpack;
@property (nonatomic) BOOL isPrivate;
@property (nonatomic) BOOL isVisible;
@property (nonatomic, strong) NSNumber *postCount;
@property (nonatomic, strong) NSString *siteBlavatar;
@property (nonatomic, strong) NSString *siteDescription;
@property (nonatomic, strong) NSNumber *siteID;
@property (nonatomic, strong) NSString *siteName;
@property (nonatomic, strong) NSString *siteURL;
@property (nonatomic, strong) NSNumber *subscriberCount;
@property (nonatomic, strong) NSString *postsEndpoint;
@property (nonatomic, strong) RemoteReaderSiteInfoSubscriptionPost *postSubscription;
@property (nonatomic, strong) RemoteReaderSiteInfoSubscriptionEmail *emailSubscription;
@end
