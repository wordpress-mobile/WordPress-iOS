#import "MenuItemTypeSelectionView.h"
#import "MenusDesign.h"
#import "MenuItemTypeCell.h"

@interface MenuItemTypeSelectionView () <MenuItemTypeViewDelegate, UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, strong) IBOutlet UITableView *tableView;

@end

@implementation MenuItemTypeSelectionView

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    self.backgroundColor = [UIColor whiteColor];
    self.translatesAutoresizingMaskIntoConstraints = NO;
}

- (NSString *)titleForType:(MenuItemType)type
{
    NSString *title = nil;
    switch (type) {
        case MenuItemTypePage:
            title = NSLocalizedString(@"Page", @"");
            break;
        case MenuItemTypeLink:
            title = NSLocalizedString(@"Link", @"");
            break;
        case MenuItemTypeCategory:
            title = NSLocalizedString(@"Category", @"");
            break;
        case MenuItemTypeTag:
            title = NSLocalizedString(@"Tag", @"");
            break;
        case MenuItemTypePost:
            title = NSLocalizedString(@"Post", @"");
            break;
        default:
            break;
    }
    
    return title;
}
 
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 0;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return nil;
}

#pragma mark - MenuItemTypeViewDelegate

- (void)itemTypeViewSelected:(MenuItemTypeCell *)typeView
{
    [self.delegate typeSelectionView:self selectedType:typeView.itemType];
}

@end
