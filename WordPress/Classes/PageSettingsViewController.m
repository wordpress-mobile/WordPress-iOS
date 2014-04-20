#import "PageSettingsViewController.h"
#import "PostSettingsViewController_Internal.h"

@interface PageSettingsViewController ()

@end

@implementation PageSettingsViewController

- (void)addPostPropertiesObserver {
    // noop
    // No need to observe properties for page settings
}

- (void)removePostPropertiesObserver {
    // noop
    // No need to observe properties for page settings
}


- (void)configureSections {
    self.sections = [NSMutableArray array];
    [self.sections addObject:[NSNumber numberWithInteger:PostSettingsSectionMeta]];
}

- (NSInteger)getMetaIndexSection {
    return 0;
}

@end
