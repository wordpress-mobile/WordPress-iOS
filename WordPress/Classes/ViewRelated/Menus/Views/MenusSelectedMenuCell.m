#import "MenusSelectedMenuCell.h"
#import "Menu.h"
#import "Blog.h"

@implementation MenusSelectedMenuCell

+ (CGFloat)heightForTableView:(UITableView *)tableView menu:(Menu *)menu
{
    return MenusSelectionCellDefaultHeight;
}

#pragma mark - INSTANCE


- (void)setMenu:(Menu *)menu
{
    if(_menu != menu) {
        _menu = menu;
        self.textLabel.attributedText = [self attributedDisplayText];
    }
}

- (NSString *)selectionSubtitleText
{
    NSString *localizedFormat = nil;
    
    if(self.menu.blog.menus.count > 1) {
        localizedFormat = NSLocalizedString(@"%i menus available", @"The number of menus on the site and area.");
    }else {
        localizedFormat = NSLocalizedString(@"%i menu available", @"One menu is available in the site and area");
    }
    
    return [NSString stringWithFormat:localizedFormat, self.menu.blog.menus.count];
}

- (NSString *)selectionTitleText
{
    return self.menu.name;
}

@end
