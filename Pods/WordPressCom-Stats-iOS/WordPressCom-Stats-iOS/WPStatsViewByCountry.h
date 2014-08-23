#import "WPStatsTitleCountItem.h"

@interface WPStatsViewByCountry : WPStatsTitleCountItem

@property (nonatomic, strong) NSURL *imageUrl;

+ (NSArray *)viewByCountryFromData:(NSDictionary *)countryData;

@end
