#import "HelpshiftEnabledFacade.h"
#import "HelpshiftUtils.h"

@implementation HelpshiftEnabledFacade

- (BOOL)isHelpshiftEnabled
{
    return [HelpshiftUtils isHelpshiftEnabled];
}

@end
