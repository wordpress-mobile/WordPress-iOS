#import "Page.h"

@implementation Page
@dynamic parentID;

+ (NSString *)titleForRemoteStatus:(NSNumber *)remoteStatus
{
    if ([remoteStatus intValue] == AbstractPostRemoteStatusSync) {
        return NSLocalizedString(@"Pages", @"");
    }

    return [super titleForRemoteStatus:remoteStatus];
}

@end
