#import "HelpshiftService.h"
#import "HelpshiftUtils.h"

@implementation HelpshiftService

- (BOOL)isHelpshiftEnabled
{
    return [HelpshiftUtils isHelpshiftEnabled];
}

@end
