#import "MenusSelectionView.h"
#import "Menu.h"
#import "MenuLocation.h"
#import "MenusSelectionDetailView.h"
#import "MenusDesign.h"
#import "MenusSelectionItemView.h"

NSString * const MenusSelectionViewItemChangedSelectedNotification = @"MenusSelectionViewItemChangedSelectedNotification";

@implementation MenusSelectionViewItem

+ (MenusSelectionViewItem *)itemWithMenu:(Menu *)menu
{
    MenusSelectionViewItem *item = [MenusSelectionViewItem new];
    item.name = menu.name;
    item.details = menu.details;
    item.itemObject = menu;
    return item;
}

+ (MenusSelectionViewItem *)itemWithLocation:(MenuLocation *)location
{
    MenusSelectionViewItem *item = [MenusSelectionViewItem new];
    // using the opposite here for display as the API returns the data differently than a menu object
    item.name = location.details;
    item.details = location.name;
    item.itemObject = location;
    return item;
}

- (BOOL)isMenu
{
    return [self.itemObject isKindOfClass:[Menu class]];
}

- (BOOL)isMenuLocation
{
    return [self.itemObject isKindOfClass:[MenuLocation class]];
}

- (void)setSelected:(BOOL)selected
{
    if(_selected != selected) {
        _selected = selected;
        [[NSNotificationCenter defaultCenter] postNotificationName:MenusSelectionViewItemChangedSelectedNotification object:self];
    }
}

@end

@interface MenusSelectionView () <MenusSelectionDetailViewDelegate, MenusSelectionItemViewDelegate>

@property (nonatomic, weak) IBOutlet UIStackView *stackView;
@property (nonatomic, weak) IBOutlet MenusSelectionDetailView *detailView;
@property (nonatomic, strong) NSMutableArray *itemViews;
@property (nonatomic, assign) BOOL drawsHighlighted;

@end

@implementation MenusSelectionView

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    self.translatesAutoresizingMaskIntoConstraints = NO;
    self.stackView.translatesAutoresizingMaskIntoConstraints = NO;
    self.stackView.alignment = UIStackViewAlignmentTop;
    self.stackView.spacing = 0.0;
    
    [self setupStyling];
    
    self.detailView.delegate = self;
}

- (void)setupStyling
{
    self.backgroundColor = [UIColor whiteColor];
    self.layer.cornerRadius = MenusDesignDefaultCornerRadius / 2.0;
    self.layer.masksToBounds = YES; // could be a performance hit with more implmentation
}

#pragma mark - instance

- (void)setItems:(NSArray<MenusSelectionViewItem *> *)items
{
    if(_items != items) {
        _items = items;
        [self reloadItemViews];
    }
}

- (void)setSelectedItem:(MenusSelectionViewItem *)selectedItem
{
    if(_selectedItem != selectedItem) {
        
        _selectedItem.selected = NO;
        selectedItem.selected = YES;
        _selectedItem = selectedItem;
        
        [self.detailView updatewithAvailableItems:self.items.count selectedItem:selectedItem];
    }
}

- (MenusSelectionViewItem *)itemWithItemObjectEqualTo:(id)itemObject
{
    MenusSelectionViewItem *matchingItem = nil;
    for(MenusSelectionViewItem *item in self.items) {
        if(item.itemObject == itemObject) {
            matchingItem = item;
            break;
        }
    }
    
    return matchingItem;
}

- (void)setSelectionExpanded:(BOOL)selectionExpanded
{
    if(_selectionExpanded != selectionExpanded) {
        _selectionExpanded = selectionExpanded;
        for(MenusSelectionItemView *itemView in self.itemViews) {
            itemView.hidden = !selectionExpanded;
            itemView.alpha = itemView.hidden ? 0.0 : 1.0;
        }
        
        self.detailView.showsDesignActive = selectionExpanded;
    }
}

- (void)setSelectionItemsExpanded:(BOOL)selectionItemsExpanded animated:(BOOL)animated
{
    if(!animated) {
        self.selectionExpanded = selectionItemsExpanded;
        return;
    }
    
    [UIView animateWithDuration:0.25 delay:0.0 options:UIViewAnimationOptionCurveEaseOut animations:^{
        
        self.selectionExpanded = selectionItemsExpanded;
        
    } completion:^(BOOL finished) {
        
    }];
}

#pragma mark - private

- (void)reloadItemViews
{
    // remove the current itemViews
    for(UIView *view in self.itemViews) {
        [self.stackView removeArrangedSubview:view];
        [view removeFromSuperview];
    }
    
    self.itemViews = [NSMutableArray array];
    
    // add new itemViews
    int i = 0;
    MenusSelectionItemView *lastItemView = nil;
    for(MenusSelectionViewItem *item in self.items) {
                
        MenusSelectionItemView *itemView = [[MenusSelectionItemView alloc] init];
        itemView.item = item;
        itemView.delegate = self;
        
        // setup ordering to help with any drawing
        lastItemView.nextItemView = itemView;
        itemView.previousItemView = lastItemView;
        
        NSLayoutConstraint *heightContrainst = [itemView.heightAnchor constraintEqualToConstant:50];
        heightContrainst.priority = UILayoutPriorityDefaultHigh;
        heightContrainst.active = YES;
        itemView.hidden = YES;

        [self.itemViews addObject:itemView];
        [self.stackView addArrangedSubview:itemView];
        
        // set the width/trailing anchor equal to the stackView
        [itemView.trailingAnchor constraintEqualToAnchor:self.stackView.trailingAnchor].active = YES;
        
        i++;
        lastItemView = itemView;
    }
}

#pragma mark - drawing

- (void)setDrawsHighlighted:(BOOL)drawsHighlighted
{
    if(_drawsHighlighted != drawsHighlighted) {
        _drawsHighlighted = drawsHighlighted;
        self.backgroundColor = drawsHighlighted ? [UIColor colorWithRed:0.99 green:0.99 blue:1.0 alpha:1.0] : [UIColor whiteColor];
    }
}

#pragma mark - delegate helpers

- (void)tellDelegateUserInteractionDetectedForTogglingExpansion
{
    [self.delegate userInteractionDetectedForTogglingSelectionView:self expand:!self.selectionExpanded];
}

- (void)tellDelegateSelectedItem:(MenusSelectionViewItem *)item
{
    [self.delegate selectionView:self selectedItem:item];
}

#pragma mark - MenusSelectionDetailViewDelegate

- (void)selectionDetailView:(MenusSelectionDetailView *)detailView tapGestureRecognized:(UITapGestureRecognizer *)tap
{
    [self tellDelegateUserInteractionDetectedForTogglingExpansion];
}

- (void)selectionDetailView:(MenusSelectionDetailView *)detailView touchesHighlightedStateChanged:(BOOL)highlighted
{
    self.drawsHighlighted = highlighted;
}

#pragma mark - MenusSelectionItemViewDelegate

- (void)selectionItemViewWasSelected:(MenusSelectionItemView *)itemView
{
    MenusSelectionViewItem *selectedItem = itemView.item;
    [self setSelectedItem:selectedItem];
    [self tellDelegateSelectedItem:selectedItem];
}

@end
