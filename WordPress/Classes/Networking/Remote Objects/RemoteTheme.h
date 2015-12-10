#import <Foundation/Foundation.h>

@interface RemoteTheme : NSObject

@property (nonatomic, assign) BOOL active;
@property (nonatomic, strong) NSString *author;
@property (nonatomic, strong) NSString *authorUrl;
@property (nonatomic, strong) NSString *desc;
@property (nonatomic, strong) NSString *demoUrl;
@property (nonatomic, strong) NSString *downloadUrl;
@property (nonatomic, strong) NSDate *launchDate;
@property (nonatomic, strong) NSString *name;
@property (nonatomic, assign) NSInteger order;
@property (nonatomic, strong) NSNumber *popularityRank;
@property (nonatomic, strong) NSString *previewUrl;
@property (nonatomic, strong) NSString *price;
@property (nonatomic, strong) NSNumber *purchased;
@property (nonatomic, strong) NSString *screenshotUrl;
@property (nonatomic, strong) NSString *stylesheet;
@property (nonatomic, strong) NSString *themeId;
@property (nonatomic, strong) NSNumber *trendingRank;
@property (nonatomic, strong) NSString *version;

@end
