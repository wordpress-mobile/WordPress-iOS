#import "WPStatsMixpanelClient.h"

@implementation WPStatsMixpanelClient

- (void)track:(WPStat)stat
{
    NSLog(@"Track %d on Mixpanel", stat);
}

- (void)track:(WPStat)stat withProperties:(NSDictionary *)properties
{
    NSLog(@"Track %d on Mixpanel with properties : %@", stat, properties);
}

@end
