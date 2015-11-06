#import "MenusSelectionItemView.h"
#import "MenusSelectionView.h"
#import "Menu.h"
#import "MenuLocation.h"

@implementation MenusSelectionViewItem

+ (MenusSelectionViewItem *)itemWithMenu:(Menu *)menu
{
    MenusSelectionViewItem *item = [MenusSelectionViewItem new];
    item.name = menu.name;
    item.details = menu.details;
    return item;
}

+ (MenusSelectionViewItem *)itemWithLocation:(MenuLocation *)location
{
    MenusSelectionViewItem *item = [MenusSelectionViewItem new];
    item.name = location.details;
    item.details = location.name;
    return item;
}

@end

@interface MenusSelectionItemView ()

@property (nonatomic, strong) UILabel *label;

@end

@implementation MenusSelectionItemView

- (id)init
{
    self = [super init];
    if(self) {
        
        [self setup];
    }
    
    return self;
}
- (void)setup
{
    
}

@end
