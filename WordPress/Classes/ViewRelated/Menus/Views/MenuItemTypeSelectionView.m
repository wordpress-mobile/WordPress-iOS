#import "MenuItemTypeSelectionView.h"
#import "MenusDesign.h"
#import "MenuItemTypeCell.h"

@implementation MenuItemSelectionType

- (NSString *)title
{
    NSString *title = nil;
    switch (self.itemType) {
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

- (NSString*)iconImageName
{
    NSString *icon = nil;
    icon = @"icon-menus-document";
    return icon;
}

@end

@implementation MenuItemTypeSelectionTableView

- (void)drawRect:(CGRect)rect
{
    [super drawRect:rect];
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSaveGState(context);
    CGContextSetLineWidth(context, 2.0);
    CGContextSetStrokeColorWithColor(context, [[WPStyleGuide greyLighten30] CGColor]);
    CGContextMoveToPoint(context, rect.size.width, 0);
    CGContextAddLineToPoint(context, rect.size.width, rect.size.height);
    CGContextStrokePath(context);
    CGContextRestoreGState(context);
}

@end

@interface MenuItemTypeSelectionView () <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, strong) NSMutableArray *selectionTypes;
@property (nonatomic, strong) MenuItemSelectionType *selectedType;

@end

@implementation MenuItemTypeSelectionView

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    self.backgroundColor = [UIColor whiteColor];
    self.translatesAutoresizingMaskIntoConstraints = NO;
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.estimatedRowHeight = MenusDesignGeneralCellHeight;
    self.tableView.rowHeight = MenusDesignGeneralCellHeight;
    self.tableView.clipsToBounds = NO;
    
    MenuItemSelectionType *selection = [self addSelectionType:MenuItemTypePage];
    selection.selected = YES;
    self.selectedType = selection;
    [self addSelectionType:MenuItemTypeLink];
    [self addSelectionType:MenuItemTypeCategory];
    [self addSelectionType:MenuItemTypeTag];
    [self addSelectionType:MenuItemTypePost];
    
    [self.tableView reloadData];
}

- (MenuItemSelectionType *)addSelectionType:(MenuItemType)type
{
    if(!self.selectionTypes) {
        self.selectionTypes = [NSMutableArray array];
    }
    
    MenuItemSelectionType *selection = [MenuItemSelectionType new];
    selection.itemType = type;
    [self.selectionTypes addObject:selection];
    
    return selection;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.selectionTypes.count;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    MenuItemSelectionType *selection = [self.selectionTypes objectAtIndex:indexPath.row];
    MenuItemTypeCell *typeCell = (MenuItemTypeCell *)cell;
    typeCell.selectionType = selection;
    typeCell.drawingShouldIgnoreTopBorder = indexPath.row == 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *identifier = @"MenuItemTypeCell";
    MenuItemTypeCell *cell = (MenuItemTypeCell *)[tableView dequeueReusableCellWithIdentifier:identifier];
    if(!cell) {
        cell = [[MenuItemTypeCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier];
    }
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    MenuItemSelectionType *selection = [self.selectionTypes objectAtIndex:indexPath.row];
    if(selection != self.selectedType) {
        selection.selected = YES;
        self.selectedType.selected = NO;
        self.selectedType = selection;
        [self.tableView reloadData];
    }
    
    [self.delegate typeSelectionView:self selectedType:selection.itemType];
}

@end
