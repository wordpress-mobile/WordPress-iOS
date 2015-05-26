#import "Page.h"
#import "NSDate+StringFormatting.h"
#import <FormatterKit/TTTTimeIntervalFormatter.h>
#import <WordPress-iOS-Shared/NSString+XMLExtensions.h>

static const NSTimeInterval TwentyFourHours = 86400;

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
    NSTimeInterval interval = [self.date_created_gmt timeIntervalSinceNow];
    if (interval > 0 && interval < TwentyFourHours) {
        return NSLocalizedString(@"later today", @"Later today");
    }

    static TTTTimeIntervalFormatter *timeIntervalFormatter;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        timeIntervalFormatter = [[TTTTimeIntervalFormatter alloc] init];
        timeIntervalFormatter.leastSignificantUnit = NSCalendarUnitDay;
        [timeIntervalFormatter setUsesIdiomaticDeicticExpressions:YES];
        [timeIntervalFormatter setPresentDeicticExpression:NSLocalizedString(@"today", @"Today")];
    });

    return [timeIntervalFormatter stringForTimeInterval:interval];
}

@end
