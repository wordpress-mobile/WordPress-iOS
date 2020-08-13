#import "MenusSelectionView.h"
#import "MenusSelectionDetailView.h"
#import "MenusSelectionItemView.h"
#import "Menu+ViewDesign.h"
#import "MenuLocation.h"
#import <WordPressShared/WPDeviceIdentification.h>
#import "WordPress-Swift.h"

@interface MenusSelectionView () <MenusSelectionDetailViewDelegate, MenusSelectionItemViewDelegate>

@property (nonatomic, strong, readonly) NSMutableArray <MenusSelectionItem *> *items;
@property (nonatomic, weak) IBOutlet UIStackView *stackView;
@property (nonatomic, weak) IBOutlet MenusSelectionDetailView *detailView;
@property (nonatomic, strong, readonly) NSMutableArray *itemViews;
@property (nonatomic, strong) MenusSelectionItemView *addNewItemView;
@property (nonatomic, assign) BOOL drawsHighlighted;
@property (nonatomic, strong, nullable) MenusSelectionItem *selectedItemLocation;

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

    [self prepareForVoiceOver];
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
    [self setSelectedItem:selectedItem location:nil];
}

- (void)setSelectedItem:(MenusSelectionItem *)selectedItem location:(MenusSelectionItem *)location
{
    if (_selectedItem != selectedItem) {

        _selectedItem.selected = NO;
        selectedItem.selected = YES;
        _selectedItem = selectedItem;
        _selectedItemLocation = location;

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
        [self prepareForVoiceOver];
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

- (void)prepareForVoiceOver
{
    if ([self.selectedItem isMenuLocation]) {
        [self configureLocationAccessibility];
    } else if ([self.selectedItem isMenu] && self.selectedItemLocation != nil) {
        [self configureMenuAccessibility];
    }
    self.detailView.accessibilityValue = self.selectionItemsExpanded ? @"Expanded" : nil;
}

- (void)configureLocationAccessibility
{
    // Menu in area: Header. 3 menu areas in this theme. Button. [hint] Expands to select a different menu location.
    NSString *format = NSLocalizedString(@"Menu area: %@, %@", @"Screen reader string too choose a menu area to edit. First %@ is the name of the menu area (Primary, Footer, etc...). Second %@ is an already localized string saying the number of areas in this theme.");
    self.detailView.accessibilityLabel = [NSString stringWithFormat:format,
                                          self.selectedItem.displayName,
                                          self.detailView.subTitleLabel.text];
    self.detailView.accessibilityHint = NSLocalizedString(@"Expands to select a different menu area", @"Screen reader hint (non-imperative) about what does the site menu area selector button does.");
}

- (void)configureMenuAccessibility
{
    // Menu in area Header: Primary. 3 menus available. Button. [hint] Expands to select a different menu to edit.
    NSString *format = NSLocalizedString(@"Menu in area %@: %@, %@", @"Screen reader string too choose a menu to edit. First %@ is the name of the menu area (Primary, Footer, etc...). Second %@ is name of the menu currently selected. Third is an already localized string saying the number of menus available in the menu area selected.");
    self.detailView.accessibilityLabel = [NSString stringWithFormat:format,
                                          self.selectedItemLocation.displayName,
                                          self.selectedItem.displayName,
                                          self.detailView.subTitleLabel.text];
    self.detailView.accessibilityHint = NSLocalizedString(@"Expands to select a different menu", @"Screen reader hint (non-imperative) about what does the site menu selector button does.");
}

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
        [self prepareForVoiceOver];
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
        [self prepareForVoiceOver];
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
