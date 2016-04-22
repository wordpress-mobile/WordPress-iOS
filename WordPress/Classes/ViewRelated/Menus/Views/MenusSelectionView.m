#import "MenusSelectionView.h"
#import "MenusSelectionDetailView.h"
#import "MenusSelectionItemView.h"
#import "Menu+ViewDesign.h"

@interface MenusSelectionView () <MenusSelectionDetailViewDelegate, MenusSelectionItemViewDelegate>

@property (nonatomic, strong) NSMutableArray <MenusSelectionItem *> *items;
@property (nonatomic, weak) IBOutlet UIStackView *stackView;
@property (nonatomic, weak) IBOutlet MenusSelectionDetailView *detailView;
@property (nonatomic, strong) NSMutableArray *itemViews;
@property (nonatomic, strong) MenusSelectionItemView *addNewItemView;
@property (nonatomic, assign) BOOL drawsHighlighted;

@property (nonatomic, strong) CALayer *leftBorder;
@property (nonatomic, strong) CALayer *rightBorder;

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
    self.layer.borderColor = [[WPStyleGuide greyLighten20] CGColor];
    self.layer.borderWidth = MenusDesignStrokeWidth;
}

#pragma mark - instance

- (void)setSelectionType:(MenusSelectionViewType)selectionType
{
    if (_selectionType != selectionType) {
        _selectionType = selectionType;
        if (selectionType == MenusSelectionViewTypeMenus) {
            if (!self.addNewItemView) {
                MenusSelectionItemView *itemView = [self insertSelectionItemViewWithItem:[MenusSelectionAddMenuItem new]];
                self.addNewItemView = itemView;
                [self.stackView addArrangedSubview:itemView];
            }
        }
    }
}

- (void)setSelectedItem:(MenusSelectionItem *)selectedItem
{
    if (_selectedItem != selectedItem) {
        
        _selectedItem.selected = NO;
        selectedItem.selected = YES;
        _selectedItem = selectedItem;
        
        [self updateDetailsView];
    }
}

- (void)addSelectionViewItem:(MenusSelectionItem *)selectionItem
{
    [self.items addObject:selectionItem];
    [self insertSelectionItemViewWithItem:selectionItem];
    
    // Ensure the add new  item is at the bottom of the stack
    [self.stackView insertArrangedSubview:self.addNewItemView atIndex:self.stackView.arrangedSubviews.count - 1];
    
    [self updateDetailsView];
}

- (void)removeSelectionItem:(MenusSelectionItem *)selectionItem
{
    MenusSelectionItemView *itemView = [self itemViewForSelectionItem:selectionItem];
    [self.stackView removeArrangedSubview:itemView];
    [self.itemViews removeObject:itemView];
    [itemView removeFromSuperview];
    [self.items removeObject:selectionItem];
    
    [self updateDetailsView];
}

- (void)removeAllSelectionItems
{
    NSArray *items = [NSArray arrayWithArray:self.items];
    for (MenusSelectionItem *item in items) {
        [self removeSelectionItem:item];
    }
}

- (MenusSelectionItem *)itemWithItemObjectEqualTo:(id)itemObject
{
    MenusSelectionItem *matchingItem = nil;
    for (MenusSelectionItem *item in self.items) {
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
        for (MenusSelectionItemView *itemView in self.itemViews) {
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
    } completion:nil];
}

#pragma mark - private

- (MenusSelectionItemView *)insertSelectionItemViewWithItem:(MenusSelectionItem *)item
{
    MenusSelectionItemView *itemView = [[MenusSelectionItemView alloc] init];
    itemView.item = item;
    itemView.delegate = self;
    
    NSLayoutConstraint *heightContrainst = [itemView.heightAnchor constraintEqualToConstant:44];
    heightContrainst.priority = UILayoutPriorityDefaultHigh;
    heightContrainst.active = YES;
    itemView.hidden = YES;
    
    [self.itemViews addObject:itemView];
    [self.stackView addArrangedSubview:itemView];
    
    // set the width/trailing anchor equal to the stackView
    [itemView.trailingAnchor constraintEqualToAnchor:self.stackView.trailingAnchor].active = YES;
    
    // setup ordering to help with any drawing
    MenusSelectionItemView *lastItemView = nil;
    for (MenusSelectionItemView *itemView in self.itemViews) {
        lastItemView.nextItemView = itemView;
        itemView.previousItemView = lastItemView;
        lastItemView = itemView;
    }
    
    return itemView;
}

- (MenusSelectionItemView *)itemViewForSelectionItem:(MenusSelectionItem *)item
{
    MenusSelectionItemView *itemView = nil;
    for (MenusSelectionItemView *view in self.itemViews) {
        if (view.item == item) {
            itemView = view;
            break;
        }
    }
    return itemView;
}

- (void)updateDetailsView
{
    if (self.selectedItem) {
        [self.detailView updatewithAvailableItems:self.items.count selectedItem:self.selectedItem];
    }
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

- (void)tellDelegateSelectedItem:(MenusSelectionItem *)item
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
    if (itemView == self.addNewItemView) {
        
        [self.delegate selectionViewSelectedOptionForCreatingNewItem:self];
        
    } else {
        
        MenusSelectionItem *selectedItem = itemView.item;
        [self setSelectedItem:selectedItem];
        [self tellDelegateSelectedItem:selectedItem];
    }
}

#pragma mark - notifications

- (void)selectionItemObjectWasUpdatedNotification:(NSNotification *)notification
{
    MenusSelectionItem *updatedItem = notification.object;
    BOOL haveItem = NO;
    for (MenusSelectionItem *item in self.items) {
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
    for (MenusSelectionItemView *itemView in self.itemViews) {
        
        if (itemView.item == updatedItem) {
            itemView.item = updatedItem;
            break;
        }
    }
}

@end
