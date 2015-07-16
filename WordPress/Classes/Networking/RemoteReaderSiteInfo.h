#import <Foundation/Foundation.h>

@interface RemoteReaderSiteInfo : NSObject
@property (nonatomic, strong) NSNumber *siteID;
@property (nonatomic, strong) NSString *siteName;
@property (nonatomic, strong) NSString *siteDescription;
@property (nonatomic, strong) NSString *siteURL;
@property (nonatomic) BOOL isFollowing;
@end
