#import "HelpshiftFacade.h"
#import "HelpshiftUtils.h"

@implementation HelpshiftFacade

- (BOOL)isHelpshiftEnabled
{
    return [HelpshiftUtils isHelpshiftEnabled];
}

@end
