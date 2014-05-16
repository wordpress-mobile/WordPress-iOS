#import "StatsTitleCountItem.h"

@interface StatsViewByCountry : StatsTitleCountItem

@property (nonatomic, strong) NSURL *imageUrl;

+ (NSArray *)viewByCountryFromData:(NSDictionary *)countryData;

@end
