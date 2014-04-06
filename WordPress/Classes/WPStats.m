#import "WPStats.h"

@implementation WPStats

+ (void)track:(WPStat)stat
{
    NSLog(@"Tracking : %d", stat);
}

@end
