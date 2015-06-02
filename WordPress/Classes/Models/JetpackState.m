#import "JetpackState.h"

NSString * const JetpackVersionMinimumRequired = @"3.4.3";

@implementation JetpackState

- (NSString *)description
{
    if ([self isConnected]) {
        NSString *connectedAs = self.connectedUsername;
        if (connectedAs.length == 0) {
            connectedAs = self.connectedEmail;
        }
        if (connectedAs.length == 0) {
            connectedAs = @"UNKNOWN";
        }
        return [NSString stringWithFormat:@"🚀✅ Jetpack %@ connected as %@ with site ID %@", self.version, connectedAs, self.siteID];
    } else if ([self isInstalled]) {
        return [NSString stringWithFormat:@"🚀❌ Jetpack %@ not connected", self.version];
    } else {
        return @"🚀❔Jetpack not installed";
    }
}

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
