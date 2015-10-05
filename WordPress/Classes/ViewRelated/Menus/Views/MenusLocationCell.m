#import "MenusLocationCell.h"
#import "MenuLocation.h"
#import "Blog.h"

@implementation MenusLocationCell

#pragma mark - CLASS

+ (CGFloat)heightForTableView:(UITableView *)tableView location:(MenuLocation *)location
{
    return MenusSelectionCellDefaultHeight;
}

#pragma mark - INSTANCE

- (void)setLocation:(MenuLocation *)location
{
    if(_location != location) {
        _location = location;
        self.textLabel.attributedText = [self attributedDisplayText];
    }
}

- (NSString *)selectionSubtitleText
{
    NSString *localizedFormat = nil;
    
    if(self.location.blog.menuLocations.count > 1) {
        localizedFormat = NSLocalizedString(@"%i menu areas in this theme", @"The number of menu areas available in the theme");
    }else {
        localizedFormat = NSLocalizedString(@"%i menu area in this theme", @"One menu area available in the theme");
    }
    
    return [NSString stringWithFormat:localizedFormat, self.location.blog.menuLocations.count];
}

- (NSString *)selectionTitleText
{
    return self.location.details;
}

@end
