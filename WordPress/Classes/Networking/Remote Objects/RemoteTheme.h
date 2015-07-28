#import <Foundation/Foundation.h>

@interface RemoteTheme : NSObject

@property (nonatomic, copy, readwrite) NSString *costCurrency;
@property (nonatomic, copy, readwrite) NSString *costDisplay;
@property (nonatomic, copy, readwrite) NSNumber *costNumber;
@property (nonatomic, copy, readwrite) NSString *desc;
@property (nonatomic, copy, readwrite) NSString *downloadUrl;
@property (nonatomic, copy, readwrite) NSDate *launchDate;
@property (nonatomic, copy, readwrite) NSString *name;
@property (nonatomic, copy, readwrite) NSNumber *popularityRank;
@property (nonatomic, copy, readwrite) NSString *previewUrl;
@property (nonatomic, copy, readwrite) NSString *screenshotUrl;
@property (nonatomic, copy, readwrite) NSArray *tags;
@property (nonatomic, copy, readwrite) NSString *themeId;
@property (nonatomic, copy, readwrite) NSNumber *trendingRank;
@property (nonatomic, copy, readwrite) NSString *version;

@end
