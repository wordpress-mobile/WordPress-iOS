#import "MenusSelectionView.h"
#import "Menu.h"
#import "MenuLocation.h"
#import "MenusSelectionDetailView.h"
#import "MenusSelectionItemView.h"
#import "Menu+ViewDesign.h"

NSString * const MenusSelectionViewItemChangedSelectedNotification = @"MenusSelectionViewItemChangedSelectedNotification";
NSString * const MenusSelectionViewItemUpdatedItemObjectNotification = @"MenusSelectionViewItemUpdatedItemObjectNotification";

@implementation MenusSelectionViewItem

+ (MenusSelectionViewItem *)itemWithMenu:(Menu *)menu
{
    MenusSelectionViewItem *item = [MenusSelectionViewItem new];
    item.itemObject = menu;
    return item;
}

+ (MenusSelectionViewItem *)itemWithLocation:(MenuLocation *)location
{
    MenusSelectionViewItem *item = [MenusSelectionViewItem new];
    item.itemObject = location;
    return item;
}

- (void)setSelected:(BOOL)selected
{
    if (_selected != selected) {
        _selected = selected;
        [[NSNotificationCenter defaultCenter] postNotificationName:MenusSelectionViewItemChangedSelectedNotification object:self];
    }
}

- (BOOL)isMenu
{
    return [self.itemObject isKindOfClass:[Menu class]];
}

- (BOOL)isMenuLocation
{
    return [self.itemObject isKindOfClass:[MenuLocation class]];
}

- (NSString *)displayName
{
    NSString *name = nil;
    
    if ([self isMenu]) {
        Menu *menu = self.itemObject;
        name = menu.name;
    } else  if ([self isMenuLocation]) {
        MenuLocation *location = self.itemObject;
        name = location.details;
    }
    
    return name;
}

- (void)notifyItemObjectWasUpdated
{
    [[NSNotificationCenter defaultCenter] postNotificationName:MenusSelectionViewItemUpdatedItemObjectNotification object:self];
}

@end

@interface MenusSelectionView () <MenusSelectionDetailViewDelegate, MenusSelectionItemViewDelegate>

@property (nonatomic, strong) NSMutableArray <MenusSelectionViewItem *> *items;
@property (nonatomic, weak) IBOutlet UIStackView *stackView;
@property (nonatomic, weak) IBOutlet MenusSelectionDetailView *detailView;
@property (nonatomic, strong) NSMutableArray *itemViews;
@property (nonatomic, strong) MenusSelectionItemView *addNewItemView;
@property (nonatomic, assign) BOOL drawsHighlighted;

@end

@implementation MenusSelectionView

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    self.items = [NSMutableArray arrayWithCapacity:5];
    self.itemViews = [NSMutableArray array];

    self.translatesAutoresizingMaskIntoConstraints = NO;
    self.stackView.translatesAutoresizingMaskIntoConstraints = NO;
    self.stackView.alignment = UIStackViewAlignmentTop;
    self.stackView.spacing = 0.0;
    
    [self setupStyling];
    
    self.detailView.delegate = self;
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(selectionItemObjectWasUpdatedNotification:) name:MenusSelectionViewItemUpdatedItemObjectNotification object:nil];
}

- (void)setupStyling
{
    self.backgroundColor = [UIColor whiteColor];
    self.layer.cornerRadius = MenusDesignDefaultCornerRadius / 2.0;
    self.layer.masksToBounds = YES; // could be a performance hit with more implmentation
}

#pragma mark - instance

- (void)setSelectedItem:(MenusSelectionViewItem *)selectedItem
{
    if (_selectedItem != selectedItem) {
        
        _selectedItem.selected = NO;
        selectedItem.selected = YES;
        _selectedItem = selectedItem;
        
        [self.detailView updatewithAvailableItems:self.items.count selectedItem:selectedItem];
    }
}

- (void)addSelectionViewItem:(MenusSelectionViewItem *)selectionItem
{
    if (self.selectionType == MenusSelectionViewTypeMenus && !self.addNewItemView) {
        MenusSelectionItemView *addNewItemView = [self insertSelectionItemViewWithItem:nil];
        self.addNewItemView = addNewItemView;
    }
    [self.items addObject:selectionItem];
    [self insertSelectionItemViewWithItem:selectionItem];
    [self.stackView insertArrangedSubview:self.addNewItemView atIndex:self.stackView.arrangedSubviews.count - 1];
}

- (MenusSelectionViewItem *)itemWithItemObjectEqualTo:(id)itemObject
{
    MenusSelectionViewItem *matchingItem = nil;
    for(MenusSelectionViewItem *item in self.items) {
        if (item.itemObject == itemObject) {
            matchingItem = item;
            break;
        }
    }
    
    return matchingItem;
}

- (void)setSelectionExpanded:(BOOL)selectionExpanded
{
    if (_selectionExpanded != selectionExpanded) {
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
    if (!animated) {
        self.selectionExpanded = selectionItemsExpanded;
        return;
    }
    
    [UIView animateWithDuration:0.25 delay:0.0 options:UIViewAnimationOptionCurveEaseOut animations:^{
        
        self.selectionExpanded = selectionItemsExpanded;
        
    } completion:^(BOOL finished) {
        
    }];
}

#pragma mark - private

- (MenusSelectionItemView *)insertSelectionItemViewWithItem:(MenusSelectionViewItem *)item
{
    MenusSelectionItemView *itemView = [[MenusSelectionItemView alloc] init];
    itemView.item = item;
    itemView.delegate = self;
    
    NSLayoutConstraint *heightContrainst = [itemView.heightAnchor constraintEqualToConstant:50];
    heightContrainst.priority = UILayoutPriorityDefaultHigh;
    heightContrainst.active = YES;
    itemView.hidden = YES;
    
    [self.itemViews addObject:itemView];
    [self.stackView addArrangedSubview:itemView];
    
    // set the width/trailing anchor equal to the stackView
    [itemView.trailingAnchor constraintEqualToAnchor:self.stackView.trailingAnchor].active = YES;
    
    // setup ordering to help with any drawing
    MenusSelectionItemView *lastItemView = nil;
    for(MenusSelectionItemView *itemView in self.itemViews) {
        lastItemView.nextItemView = itemView;
        itemView.previousItemView = lastItemView;
        lastItemView = itemView;
    }
    
    return itemView;
}

#pragma mark - drawing

- (void)setDrawsHighlighted:(BOOL)drawsHighlighted
{
    if (_drawsHighlighted != drawsHighlighted) {
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
    if (itemView.item) {
    
        MenusSelectionViewItem *selectedItem = itemView.item;
        [self setSelectedItem:selectedItem];
        [self tellDelegateSelectedItem:selectedItem];
    
    } else if (itemView == self.addNewItemView) {
        
        [self.delegate selectionViewSelectedOptionForCreatingNewMenu:self];
    }
}

#pragma mark - notifications

- (void)selectionItemObjectWasUpdatedNotification:(NSNotification *)notification
{
    MenusSelectionViewItem *updatedItem = notification.object;
    BOOL haveItem = NO;
    for(MenusSelectionViewItem *item in self.items) {
        if (item == updatedItem) {
            haveItem = YES;
            break;
        }
    }
    
    if (!haveItem) {
        // no updates needed
        return;
    }
    
    if (updatedItem.selected) {
        // update the detailView
        [self.detailView updatewithAvailableItems:self.items.count selectedItem:updatedItem];
    }
    
    // update any itemViews using this item
    for(MenusSelectionItemView *itemView in self.itemViews) {
        
        if (itemView.item == updatedItem) {
            itemView.item = updatedItem;
            break;
        }
    }
}

@end
