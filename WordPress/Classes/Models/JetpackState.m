#import "JetpackState.h"

NSString * const JetpackVersionMinimumRequired = @"3.4.3";

@implementation JetpackState

- (BOOL)isInstalled
{
    return self.version != nil;
}

- (BOOL)isConnected
{
    return [self isInstalled] && [self.siteID floatValue] > 0;
}

- (BOOL)isUpdatedToRequiredVersion
{
    return [self.version compare:JetpackVersionMinimumRequired options:NSNumericSearch] != NSOrderedAscending;
}

@end
