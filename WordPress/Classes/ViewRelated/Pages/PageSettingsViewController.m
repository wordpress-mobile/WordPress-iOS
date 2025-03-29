#import "PageSettingsViewController.h"
#import "PostSettingsViewController_Internal.h"
#ifdef KEYSTONE
#import "Keystone-Swift.h"
#else
#import "WordPress-Swift.h"
#endif

@interface PageSettingsViewController ()

@end

@implementation PageSettingsViewController

- (void)configureSections
{
    self.sections = @[
        @(PostSettingsSectionMeta),
        @(PostSettingsSectionFeaturedImage),
        @(PostSettingsSectionMoreOptions),
        @(PostSettingsSectionPageAttributes)
    ];
}

- (Page *)page
{
    if ([self.apost isKindOfClass:[Page class]]) {
        return (Page *)self.apost;
    }
    
    return nil;
}

@end
