#import "PageSettingsViewController.h"
#import "PostSettingsViewController_Internal.h"
#import "Page.h"

@interface PageSettingsViewController ()

@end

@implementation PageSettingsViewController

- (void)addPostPropertiesObserver
{
    // noop
    // No need to observe properties for page settings
}

- (void)removePostPropertiesObserver
{
    // noop
    // No need to observe properties for page settings
}

- (void)configureSections
{
    self.sections = [NSMutableArray array];
    [self.sections addObject:[NSNumber numberWithInteger:PostSettingsSectionMeta]];
    [self.sections addObject:[NSNumber numberWithInteger:PostSettingsSectionFeaturedImage]];    
}

- (Page *)page
{
    if ([self.apost isKindOfClass:[Page class]]) {
        return (Page *)self.apost;
    }
    
    return nil;
}

@end
