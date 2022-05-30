#import "PageSettingsViewController.h"
#import "PostSettingsViewController_Internal.h"
#import "WordPress-Swift.h"

@interface PageSettingsViewController ()

@end

@implementation PageSettingsViewController

- (void)configureSections
{
    self.sections = @[@(PostSettingsSectionMeta),@(PostSettingsSectionFeaturedImage)];
}

- (Page *)page
{
    if ([self.apost isKindOfClass:[Page class]]) {
        return (Page *)self.apost;
    }
    
    return nil;
}

@end
