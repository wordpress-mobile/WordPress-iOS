#import "PageSettingsViewController.h"
#import "PostSettingsViewController_Internal.h"
#import "Page.h"

@interface PageSettingsViewController ()

@end

@implementation PageSettingsViewController

- (void)addPostPropertiesObserver
{
    [self.apost addObserver:self
                forKeyPath:NSStringFromSelector(@selector(post_thumbnail))
                   options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld
                   context:nil];

}

- (void)removePostPropertiesObserver
{
    [self.apost removeObserver:self forKeyPath:NSStringFromSelector(@selector(post_thumbnail))];
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
