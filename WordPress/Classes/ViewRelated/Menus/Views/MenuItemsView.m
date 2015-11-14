#import "MenuItemsView.h"
#import "Menu.h"
#import "MenuItem.h"
#import "WPStyleGuide.h"
#import "MenuItemsActionableView.h"
#import "MenuItemView.h"
#import "MenuItemBlankView.h"
#import "MenusDesign.h"

@interface MenuItemsView () <MenuItemViewDelegate>

@property (nonatomic, weak) IBOutlet UIStackView *stackView;
@property (nonatomic, strong) NSMutableArray *itemViews;
@property (nonatomic, strong) NSMutableArray *blankItemViews;

@end

@implementation MenuItemsView

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    self.translatesAutoresizingMaskIntoConstraints = NO;
    self.stackView.translatesAutoresizingMaskIntoConstraints = NO;
    self.stackView.alignment = UIStackViewAlignmentTop;
    self.stackView.spacing = 0.0;
    
    [self setupStyling];
}

- (void)setupStyling
{
    self.backgroundColor = [UIColor clearColor];
}

- (void)setMenu:(Menu *)menu
{
    if(_menu != menu) {
        _menu = menu;
        [self reloadItemViews];
    }
}

- (void)reloadItemViews
{
    for(MenuItemsActionableView *itemView in self.itemViews) {
        [self.stackView removeArrangedSubview:itemView];
        [itemView removeFromSuperview];
    }
    
    self.itemViews = [NSMutableArray array];
    MenuItemView *lastItemView = nil;
    for(MenuItem *item in self.menu.items) {
                
        MenuItemView *itemView = [[MenuItemView alloc] init];
        itemView.delegate = self;
        // set up ordering to help with any drawing
        itemView.item = item;
        lastItemView.nextView = itemView;
        itemView.previousView = lastItemView;
        itemView.indentationLevel = 1;

        MenuItem *parentItem = item.parent;
        while (parentItem) {
            itemView.indentationLevel++;
            parentItem = parentItem.parent;
        }
        
        NSLayoutConstraint *heightConstraint = [itemView.heightAnchor constraintEqualToConstant:55];
        heightConstraint.priority = UILayoutPriorityDefaultHigh;
        heightConstraint.active = YES;
        
        [self.itemViews addObject:itemView];
        [self.stackView addArrangedSubview:itemView];
        
        [itemView.trailingAnchor constraintEqualToAnchor:self.stackView.trailingAnchor].active = YES;
        lastItemView = itemView;
    }
}

- (MenuItemBlankView *)blankItemViewWithType:(MenuItemBlankViewType)type level:(NSUInteger)indentationLevel
{
    MenuItemBlankView *itemView = [[MenuItemBlankView alloc] init];
    itemView.type = type;
    itemView.indentationLevel = indentationLevel;
    
    NSLayoutConstraint *heightConstraint = [itemView.heightAnchor constraintEqualToConstant:55];
    heightConstraint.priority = UILayoutPriorityDefaultHigh;
    heightConstraint.active = YES;
    
    return itemView;
}

- (void)insertBlankItemViewsAroundItemView:(MenuItemView *)toggledItemView
{
    self.blankItemViews = [NSMutableArray arrayWithCapacity:3];
    
    int index = 0;
    for(UIView *view in self.stackView.arrangedSubviews) {
        
        if(view == toggledItemView) {
            break;
        }
        
        index++;
    }
    
    {
        MenuItemBlankView *blank = [self blankItemViewWithType:MenuItemBlankViewAbove level:toggledItemView.indentationLevel];
        [self.blankItemViews addObject:blank];
        [self.stackView insertArrangedSubview:blank atIndex:index];
    }
    {
        MenuItemBlankView *blank = [self blankItemViewWithType:MenuItemBlankViewBelow level:toggledItemView.indentationLevel];
        [self.blankItemViews addObject:blank];
        [self.stackView insertArrangedSubview:blank atIndex:index + 2];
    }
    {
        MenuItemBlankView *blank = [self blankItemViewWithType:MenuItemBlankViewChild level:toggledItemView.indentationLevel + 1];
        [self.blankItemViews addObject:blank];
        [self.stackView insertArrangedSubview:blank atIndex:index + 3];
    }
    
    [self.stackView setNeedsLayout];
}

- (void)removeBlankItemViews
{
    for(MenuItemsActionableView *itemView in self.blankItemViews) {
        [self.stackView removeArrangedSubview:itemView];
        [itemView removeFromSuperview];
    }
    
    self.blankItemViews = nil;
    [self.stackView setNeedsLayout];
}

#pragma mark - MenuItemViewDelegate

- (void)itemViewAddButtonPressed:(MenuItemView *)itemView
{
    itemView.showsCancelButtonOption = YES;
    for(MenuItemView *childItemView in self.itemViews) {
        childItemView.showsEditingButtonOptions = NO;
    }
    [self insertBlankItemViewsAroundItemView:itemView];
}

- (void)itemViewCancelButtonPressed:(MenuItemView *)itemView
{
    itemView.showsCancelButtonOption = NO;
    for(MenuItemView *childItemView in self.itemViews) {
        childItemView.showsEditingButtonOptions = YES;
    }
    [self removeBlankItemViews];
}

@end
