#import "Page.h"
#import "NSDate+StringFormatting.h"
#import <WordPress-iOS-Shared/NSString+XMLExtensions.h>

@implementation Page

@dynamic parentID;

+ (NSString *)titleForRemoteStatus:(NSNumber *)remoteStatus
{
    if ([remoteStatus intValue] == AbstractPostRemoteStatusSync) {
        return NSLocalizedString(@"Pages", @"");
    }

    return [super titleForRemoteStatus:remoteStatus];
}

- (NSString *)sectionIdentifier
{
    NSInteger index = [NSDate indexForConciseStringForDate:self.date_created_gmt];
    return [NSString stringWithFormat:@"%d", index];
}

@end
