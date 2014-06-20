#import "WPStatsViewByCountry.h"

@implementation WPStatsViewByCountry

+ (NSArray *)viewByCountryFromData:(NSDictionary *)countryData {
    NSArray *initialCountryList = countryData[@"country-views"];
    NSMutableArray *finalCountryList = [NSMutableArray array];
    for (NSDictionary *country in initialCountryList) {
        WPStatsViewByCountry *viewByCountry = [[WPStatsViewByCountry alloc] initWithCountry:country];
        [finalCountryList addObject:viewByCountry];
    }
    return finalCountryList;
}

- (id)initWithCountry:(NSDictionary *)country {
    self = [super init];
    if (self) {
        self.title = country[@"country"];
        self.count = country[@"views"];
        self.imageUrl = [[NSURL alloc] initWithString:country[@"imageUrl"]];
    }
    return self;
}

@end
