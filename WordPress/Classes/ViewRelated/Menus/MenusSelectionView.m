#import "MenusSelectionView.h"
#import "MenusSelectionDetailView.h"
#import "MenusSelectionItemView.h"
#import "Menu+ViewDesign.h"
#import <WordPressShared/WPDeviceIdentification.h>
#import "WordPress-Swift.h"

@interface MenusSelectionView () <MenusSelectionDetailViewDelegate, MenusSelectionItemViewDelegate>

@property (nonatomic, strong, readonly) NSMutableArray <MenusSelectionItem *> *items;
@property (nonatomic, weak) IBOutlet UIStackView *stackView;
@property (nonatomic, weak) IBOutlet MenusSelectionDetailView *detailView;
@property (nonatomic, strong, readonly) NSMutableArray *itemViews;
@property (nonatomic, strong) MenusSelectionItemView *addNewItemView;
@property (nonatomic, assign) BOOL drawsHighlighted;

@end

@implementation MenusSelectionView

- (void)awakeFromNib
{
    [super awakeFromNib];

    self.backgroundColor = [UIColor murielListForeground];
    self.layer.borderColor = [[UIColor murielNeutral10] CGColor];
    self.layer.borderWidth = MenusDesignStrokeWidth;
    if (![WPDeviceIdentification isRetina]) {
        // Increase the stroke width on non-retina screens.
        self.layer.borderWidth = MenusDesignStrokeWidth * 2;
    }

    _items = [NSMutableArray arrayWithCapacity:5];
    _itemViews = [NSMutableArray array];

    self.translatesAutoresizingMaskIntoConstraints = NO;

    self.stackView.translatesAutoresizingMaskIntoConstraints = NO;
    self.stackView.alignment = UIStackViewAlignmentTop;
    self.stackView.spacing = 0.0;

    self.detailView.delegate = self;

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(selectionItemObjectWasUpdatedNotification:) name:MenusSelectionViewItemUpdatedItemObjectNotification object:nil];
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

- (MenusSelectionItem *)selectionItemForObject:(id)itemObject
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

- (void)setSelectionItemsExpanded:(BOOL)selectionItemsExpanded
{
    if (_selectionItemsExpanded != selectionItemsExpanded) {
        _selectionItemsExpanded = selectionItemsExpanded;
        for (MenusSelectionItemView *itemView in self.itemViews) {
            itemView.hidden = !selectionItemsExpanded;
            itemView.alpha = itemView.hidden ? 0.0 : 1.0;
        }

        self.detailView.showsDesignActive = selectionItemsExpanded;
    }
}

- (void)setSelectionItemsExpanded:(BOOL)selectionItemsExpanded animated:(BOOL)animated
{
    if (!animated) {
        self.selectionItemsExpanded = selectionItemsExpanded;
        return;
    }
    [UIView animateWithDuration:0.25 delay:0.0 options:UIViewAnimationOptionCurveEaseOut animations:^{
        self.selectionItemsExpanded = selectionItemsExpanded;
    } completion:nil];
}

#pragma mark - private

- (MenusSelectionItemView *)insertSelectionItemViewWithItem:(MenusSelectionItem *)item
{
    MenusSelectionItemView *itemView = [[MenusSelectionItemView alloc] init];
    itemView.item = item;
    itemView.delegate = self;

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

- (void)tellDelegateUserTappedForExpansion
{
    [self.delegate selectionView:self userTappedExpand:!self.selectionItemsExpanded];
}

- (void)tellDelegateSelectedItem:(MenusSelectionItem *)item
{
    [self.delegate selectionView:self selectedItem:item];
}

#pragma mark - MenusSelectionDetailViewDelegate

- (void)selectionDetailView:(MenusSelectionDetailView *)detailView tapGestureRecognized:(UITapGestureRecognizer *)tap
{
    [self tellDelegateUserTappedForExpansion];
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

        [self tellDelegateSelectedItem:itemView.item];
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
