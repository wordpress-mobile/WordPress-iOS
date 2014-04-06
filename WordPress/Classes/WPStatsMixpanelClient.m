#import "WPStatsMixpanelClient.h"

@implementation WPStatsMixpanelClient

- (void)track:(WPStat)stat
{
    NSLog(@"Track %d on Mixpanel", stat);
}

@end
