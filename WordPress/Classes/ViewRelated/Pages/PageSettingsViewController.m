#import "PageSettingsViewController.h"
#import "PostSettingsViewController_Internal.h"
#import "WordPress-Swift.h"

@interface PageSettingsViewController ()

@end

@implementation PageSettingsViewController

- (void)addPostPropertiesObserver
{
    [self.apost addObserver:self
                forKeyPath:NSStringFromSelector(@selector(featuredImage))
                   options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld
                   context:nil];

}

- (void)removePostPropertiesObserver
{
    [self.apost removeObserver:self forKeyPath:NSStringFromSelector(@selector(featuredImage))];
}

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
