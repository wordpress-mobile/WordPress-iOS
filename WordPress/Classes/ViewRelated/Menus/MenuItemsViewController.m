#import "MenuItemsViewController.h"
#import "Menu.h"
#import "MenuItem.h"
#import "MenuItemAbstractView.h"
#import "MenuItemView.h"
#import "MenuItemInsertionView.h"
#import "MenuItemsVisualOrderingView.h"
#import "ContextManager.h"
#import "Menu+ViewDesign.h"
#import "WPGUIConstants.h"
#import <WordPressShared/WPDeviceIdentification.h>
#import <WordPressShared/WPStyleGuide.h>
#import "WordPress-Swift.h"

static CGFloat const ItemHoriztonalDragDetectionWidthRatio = 0.05;
static CGFloat const ItemOrderingTouchesDetectionInset = 10.0;

@interface MenuItemsViewController () <MenuItemAbstractViewDelegate, MenuItemViewDelegate, MenuItemInsertionViewDelegate, MenuItemsVisualOrderingViewDelegate>

@property (nonatomic, strong) IBOutlet UIStackView *stackView;

@property (nonatomic, strong, readonly) NSMutableSet *itemViews;
@property (nonatomic, strong, readonly) NSMutableSet *insertionViews;
@property (nonatomic, strong) MenuItemView *itemViewForInsertionToggling;
@property (nonatomic, assign) BOOL isEditingForItemViewInsertion;

@property (nonatomic, assign) CGPoint touchesBeganLocation;
@property (nonatomic, assign) CGPoint touchesMovedLocation;
@property (nonatomic, assign) BOOL showingTouchesOrdering;

@property (nonatomic, assign) BOOL observesOrderingTouches;
@property (nonatomic, assign) BOOL observesParentChildNestingTouches;

@property (nonatomic, strong) MenuItemView *itemViewForOrdering;
@property (nonatomic, strong, readonly) MenuItemsVisualOrderingView *visualOrderingView;

@property (nonatomic, strong) UISelectionFeedbackGenerator *orderingFeedbackGenerator;

@end

@implementation MenuItemsViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.view.translatesAutoresizingMaskIntoConstraints = NO;
    self.view.backgroundColor = [UIColor murielListForeground];
    self.view.layer.borderColor = [[UIColor murielNeutral10] CGColor];
    self.view.layer.borderWidth = MenusDesignStrokeWidth;
    if (![WPDeviceIdentification isRetina]) {
        // Increase the stroke width on non-retina screens.
        self.view.layer.borderWidth = MenusDesignStrokeWidth * 2;
    }

    _itemViews = [NSMutableSet set];
    _insertionViews = [NSMutableSet setWithCapacity:3];

    self.touchesBeganLocation = CGPointZero;
    self.touchesMovedLocation = CGPointZero;
}

- (void)setMenu:(Menu *)menu
{
    if (_menu != menu) {
        _menu = menu;
        [self reloadItems];
    }
}

- (void)refreshViewWithItem:(MenuItem *)item focus:(BOOL)focusesView
{
    MenuItemView *itemView = [self itemViewForItem:item];
    [itemView refresh];
    if (focusesView) {
        [self.delegate itemsViewController:self requiresScrollingToCenterView:itemView];
    }
}

- (void)removeItem:(MenuItem *)item
{
    // Reassign any children to the parent of the item.
    BOOL parentChildUpdateNeeded = NO;
    if (item.children.count) {
        parentChildUpdateNeeded = YES;
        NSSet *children = [NSSet setWithSet:item.children];
        for (MenuItem *child in children) {
            child.parent = item.parent;
        }
    }

    // Remove the itemView from the stackView.
    MenuItemView *itemView = [self itemViewForItem:item];
    [self.stackView removeArrangedSubview:itemView];
    [itemView removeFromSuperview];
    [self.itemViews removeObject:itemView];
    itemView = nil;
    if (parentChildUpdateNeeded) {
        [self updateParentChildIndentationForItemViews];
    }

    // Remove the item from the context.
    NSManagedObjectContext *managedObjectContext = item.managedObjectContext;
    [managedObjectContext deleteObject:item];
    [managedObjectContext processPendingChanges];
    [[ContextManager sharedInstance] saveContext:managedObjectContext];
}

- (void)reloadItems
{
    NSArray *arrangedViews = [NSArray arrayWithArray:self.stackView.arrangedSubviews];
    for (MenuItemAbstractView *stackableView in arrangedViews) {
        [self.stackView removeArrangedSubview:stackableView];
        [stackableView removeFromSuperview];
    }

    [self.itemViews removeAllObjects];
    [self.insertionViews removeAllObjects];

    self.isEditingForItemViewInsertion = NO;
    self.itemViewForInsertionToggling = nil;

    for (MenuItem *item in self.menu.items) {
        [self addNewItemViewWithItem:item];
    }
}

- (MenuItemView *)addNewItemViewWithItem:(MenuItem *)item
{
    MenuItemView *itemView = [[MenuItemView alloc] init];
    itemView.delegate = self;
    itemView.item = item;
    itemView.indentationLevel = 0;

    NSLayoutConstraint *heightConstraint = [itemView.heightAnchor constraintGreaterThanOrEqualToConstant:MenuItemsStackableViewDefaultHeight];
    heightConstraint.active = YES;
    [self.itemViews addObject:itemView];
    [self.stackView addArrangedSubview:itemView];
    [itemView.widthAnchor constraintEqualToAnchor:self.view.widthAnchor].active = YES;

    MenuItem *parentItem = item.parent;
    while (parentItem) {
        itemView.indentationLevel++;
        parentItem = parentItem.parent;
    }

    return itemView;
}

- (void)updateParentChildIndentationForItemViews
{
    for (UIView *arrangedView in self.stackView.arrangedSubviews) {
        if (![arrangedView isKindOfClass:[MenuItemView class]]) {
            continue;
        }

        MenuItemView *itemView = (MenuItemView *)arrangedView;
        itemView.indentationLevel = 0;

        MenuItem *parentItem = itemView.item.parent;
        while (parentItem) {
            itemView.indentationLevel++;
            parentItem = parentItem.parent;
        }
    }
}

- (MenuItemInsertionView *)addNewInsertionViewWithOrder:(MenuItemInsertionOrder)insertionOrder forItemView:(MenuItemView *)itemView
{
    NSInteger index = [self.stackView.arrangedSubviews indexOfObject:itemView];
    MenuItemInsertionView *insertionView = [[MenuItemInsertionView alloc] init];
    insertionView.delegate = self;
    insertionView.insertionOrder = insertionOrder;

    switch (insertionOrder) {
        case MenuItemInsertionOrderAbove:
            insertionView.indentationLevel = itemView.indentationLevel;
            break;
        case MenuItemInsertionOrderBelow:
            insertionView.indentationLevel = itemView.indentationLevel;
            index++;
            break;
        case MenuItemInsertionOrderChild:
            insertionView.indentationLevel = itemView.indentationLevel + 1;
            index += 2;
            break;
    }

    NSLayoutConstraint *heightConstraint = [insertionView.heightAnchor constraintGreaterThanOrEqualToConstant:MenuItemsStackableViewDefaultHeight];
    heightConstraint.priority = UILayoutPriorityDefaultHigh;
    heightConstraint.active = YES;

    [self.insertionViews addObject:insertionView];
    [self.stackView insertArrangedSubview:insertionView atIndex:index];

    [insertionView.widthAnchor constraintEqualToAnchor:self.stackView.widthAnchor].active = YES;

    return insertionView;
}

- (void)insertInsertionItemViewsAroundItemView:(MenuItemView *)toggledItemView
{
    if (self.isEditingForItemViewInsertion) {
        [self removeItemInsertionViews:NO];
    }

    self.isEditingForItemViewInsertion = YES;

    self.itemViewForInsertionToggling = toggledItemView;
    toggledItemView.showsCancelButtonOption = YES;
    toggledItemView.showsEditingButtonOptions = NO;

    [self addNewInsertionViewWithOrder:MenuItemInsertionOrderAbove forItemView:toggledItemView];
    [self addNewInsertionViewWithOrder:MenuItemInsertionOrderBelow forItemView:toggledItemView];
    [self addNewInsertionViewWithOrder:MenuItemInsertionOrderChild forItemView:toggledItemView];
}

- (void)insertItemInsertionViewsAroundItemView:(MenuItemView *)toggledItemView animated:(BOOL)animated
{
    BOOL wasEditing = self.isEditingForItemViewInsertion;

    CGRect previousRect = toggledItemView.frame;
    CGRect updatedRect = toggledItemView.frame;

    [self insertInsertionItemViewsAroundItemView:toggledItemView];

    if (!animated) {
        return;
    }

    // since we are adding content above the toggledItemView, the toggledItemView (focus) will move downwards with the updated content size
    updatedRect.origin.y += MenuItemsStackableViewDefaultHeight;

    for (MenuItemInsertionView *insertionView in self.insertionViews) {
        insertionView.hidden = YES;
        insertionView.alpha = WPAlphaZero;
    }
    [UIView animateWithDuration:WPAnimationDurationDefault animations:^{

        for (MenuItemInsertionView *insertionView in self.insertionViews) {
            insertionView.hidden = NO;
            insertionView.alpha = WPAlphaFull;
        }
        // inform the delegate to handle this content change based on the rect we are focused on
        // a delegate will likely scroll the content with the size change
        if (!wasEditing) {
            [self.delegate itemsViewAnimatingContentSizeChanges:self focusedRect:previousRect updatedFocusRect:updatedRect];
        }

    } completion:nil];
}

- (void)removeItemInsertionViews
{
    for (MenuItemInsertionView *insertionView in self.insertionViews) {
        [self.stackView removeArrangedSubview:insertionView];
        [insertionView removeFromSuperview];
    }

    [self.insertionViews removeAllObjects];
    self.itemViewForInsertionToggling = nil;
}

- (void)removeItemInsertionViews:(BOOL)animated
{
    self.isEditingForItemViewInsertion = NO;
    self.itemViewForInsertionToggling.showsCancelButtonOption = NO;
    self.itemViewForInsertionToggling.showsEditingButtonOptions = YES;

    if (!animated) {
        [self removeItemInsertionViews];
        return;
    }

    CGRect previousRect = self.itemViewForInsertionToggling.frame;
    CGRect updatedRect = previousRect;
    // since we are removing content above the toggledItemView, the toggledItemView (focus) will move upwards with the updated content size
    updatedRect.origin.y -= MenuItemsStackableViewDefaultHeight;

    [UIView animateWithDuration:WPAnimationDurationDefault delay:0.0 options:0 animations:^{

        for (MenuItemInsertionView *insertionView in self.insertionViews) {
            insertionView.hidden = YES;
            insertionView.alpha = WPAlphaZero;
        }
        // inform the delegate to handle this content change based on the rect we are focused on
        // a delegate will likely scroll the content with the size change
        [self.delegate itemsViewAnimatingContentSizeChanges:self focusedRect:previousRect updatedFocusRect:updatedRect];

    } completion:^(BOOL finished) {

        [self removeItemInsertionViews];
    }];
}

- (MenuItemView *)itemViewForItem:(MenuItem *)item
{
    MenuItemView *itemView = nil;
    for (MenuItemView *arrangedItemView in self.itemViews) {
        if (arrangedItemView.item == item) {
            itemView = arrangedItemView;
            break;
        }
    }
    return itemView;
}

#pragma mark - touches

- (void)resetTouchesMovedObservationVectorX
{
    CGPoint reset = CGPointZero;
    reset.x = self.touchesMovedLocation.x;
    reset.y = self.touchesBeganLocation.y;
    self.touchesBeganLocation = reset;
}

- (void)resetTouchesMovedObservationVectorY
{
    CGPoint reset = CGPointZero;
    reset.y = self.touchesMovedLocation.y;
    reset.x = self.touchesBeganLocation.x;
    self.touchesBeganLocation = reset;
}

- (void)updateWithTouchesStarted:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    [self prepareOrderingFeedbackGenerator];

    CGPoint location = [[touches anyObject] locationInView:self.view];

    self.touchesBeganLocation = location;

    if (self.isEditingForItemViewInsertion) {
        return;
    }

    for (MenuItemView *itemView in self.itemViews) {
        if (CGRectContainsPoint(itemView.frame, [[touches anyObject] locationInView:itemView.superview])) {
            self.observesParentChildNestingTouches = YES;
        } else {
            continue;
        }
        if (CGRectContainsPoint([itemView orderingToggleRect], [[touches anyObject] locationInView:itemView])) {
            self.observesOrderingTouches = YES;
        }
        if (self.observesParentChildNestingTouches || self.observesOrderingTouches) {
            [self beginOrdering:itemView];
            break;
        }
    }
}

- (void)updateWithTouchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    CGPoint location = [[touches anyObject] locationInView:self.view];

    CGPoint startLocation = self.touchesBeganLocation;

    self.touchesMovedLocation = location;
    CGPoint vector = CGPointZero;
    vector.x = location.x - startLocation.x;
    vector.y = location.y - startLocation.y;

    if (self.isEditingForItemViewInsertion || !(self.observesOrderingTouches || self.observesParentChildNestingTouches)) {
        return;
    }

    if (self.observesOrderingTouches) {
        // Only show ordering visual for ordering, not for parent/child nesting.
        [self showOrdering];
    }
    [self orderingTouchesMoved:touches withEvent:event vector:vector];
}

- (void)updateWithTouchesStopped:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    self.observesOrderingTouches = NO;
    self.observesParentChildNestingTouches = NO;
    self.touchesBeganLocation = CGPointZero;
    self.touchesMovedLocation = CGPointZero;
    [self endReordering];
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    [super touchesBegan:touches withEvent:event];
    [self updateWithTouchesStarted:touches withEvent:event];
}

- (void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    [super touchesMoved:touches withEvent:event];
    [self updateWithTouchesMoved:touches withEvent:event];
}

- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    [super touchesEnded:touches withEvent:event];
    [self updateWithTouchesStopped:touches withEvent:event];
}

- (void)touchesCancelled:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    [super touchesCancelled:touches withEvent:event];
    [self updateWithTouchesStopped:touches withEvent:event];
}

#pragma mark - ordering

- (void)beginOrdering:(MenuItemView *)orderingView
{
    self.itemViewForOrdering = orderingView;
    [self prepareVisualOrderingViewWithItemView:orderingView];
}

- (void)showOrdering
{
    if (!self.showingTouchesOrdering) {
        self.showingTouchesOrdering = YES;
        [self showVisualOrderingView];
        [self toggleOrderingPlaceHolder:YES forItemViewsWithSelectedItemView:self.itemViewForOrdering];

        // Apple's documentation says not to trigger on initial selection,
        // but the built-in taptics for UITableView *does* trigger when you first
        // start reordering. So, let's match that behavior.
        [self triggerOrderingFeedbackGenerator];
    }
}

- (void)hideOrdering
{
    self.showingTouchesOrdering = NO;
    [self toggleOrderingPlaceHolder:NO forItemViewsWithSelectedItemView:self.itemViewForOrdering];
    [self hideVisualOrderingView];
}

- (void)endReordering
{
    // cleanup

    [self hideOrdering];
    self.itemViewForOrdering = nil;
    [self.delegate itemsViewController:self prefersScrollingEnabled:YES];
    [self cleanUpOrderingFeedbackGenerator];
}

- (void)orderingTouchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event vector:(CGPoint)vector
{
    if (!self.itemViewForOrdering) {
        return;
    }

    const CGPoint touchPoint = [[touches anyObject] locationInView:self.view];
    MenuItemView *selectedItemView = self.itemViewForOrdering;
    MenuItem *selectedItem = selectedItemView.item;
    BOOL modelUpdated = NO;

    if (self.observesParentChildNestingTouches) {
        //// horiztonal indentation detection (child relationships)
        //// detect if the user is moving horizontally to the right or left to change the indentation

        // first check to see if we should pay attention to touches that might signal a change in indentation
        const BOOL detectedHorizontalOrderingTouches = fabs(vector.x) > (selectedItemView.frame.size.width * ItemHoriztonalDragDetectionWidthRatio); // a travel of x% should be considered for updating relationships

        [self.visualOrderingView updateVisualOrderingWithTouchLocation:touchPoint vector:vector];

        if (detectedHorizontalOrderingTouches) {

            NSOrderedSet *orderedItems = self.menu.items;
            NSUInteger selectedItemIndex = [orderedItems indexOfObject:selectedItem];

            // check if not first item in order
            if (selectedItemIndex > 0) {
                // detect the child/parent relationship changes and update the model
                if (vector.x > 0) {
                    // trying to make a child
                    MenuItem *previousItem = [orderedItems objectAtIndex:selectedItemIndex - 1];
                    MenuItem *parent = previousItem;
                    MenuItem *newParent = nil;
                    while (parent) {
                        if (parent == selectedItem.parent) {
                            break;
                        }
                        newParent = parent;
                        parent = parent.parent;
                    }

                    if (newParent) {
                        selectedItem.parent = newParent;
                        modelUpdated = YES;
                    }

                } else  {
                    if (selectedItem.parent) {

                        MenuItem *lastChildItem = [selectedItem.parent lastDescendantInOrderedItems:orderedItems];
                        // only the lastChildItem can move up the tree, otherwise it would break the visual child/parent relationship
                        if (selectedItem == lastChildItem) {
                            // try to move up the parent tree
                            MenuItem *parent = selectedItem.parent.parent;
                            selectedItem.parent = parent;
                            modelUpdated = YES;
                        }
                    }
                }
            }

            // reset the vector to observe the next delta of interest
            [self resetTouchesMovedObservationVectorX];
        }
    }

    if (self.observesOrderingTouches) {
        [self.delegate itemsViewController:self prefersScrollingEnabled:NO];

        //// vertical ordering detection (order of the items in the menu)
        if (!CGRectContainsPoint(selectedItemView.frame, touchPoint)) {

            //// if the touch is over a different item, detect which item to replace the ordering with

            for (MenuItemView *itemView in self.itemViews) {
                // enumerate the itemViews lists since we don't care about other views in the stackView.arrangedSubviews list
                if (itemView == selectedItemView) {
                    continue;
                }
                // detect if the touch within a padded inset of an itemView under the touchPoint
                const CGRect orderingDetectionRect = CGRectInset(itemView.frame, ItemOrderingTouchesDetectionInset, ItemOrderingTouchesDetectionInset);
                if (CGRectContainsPoint(orderingDetectionRect, touchPoint)) {

                    // reorder the model if needed or available
                    BOOL orderingUpdate = [self handleOrderingTouchForItemView:selectedItemView withOtherItemView:itemView touchLocation:touchPoint];
                    if (orderingUpdate) {
                        modelUpdated = YES;
                    }
                    break;
                }
            }
        }
    }

    // update the views based on the model changes
    if (modelUpdated) {
        [self updateParentChildIndentationForItemViews];
        [self triggerOrderingFeedbackGenerator];
        [self.visualOrderingView updateForVisualOrderingMenuItemsModelChange];
        [self.delegate itemsViewController:self didUpdateMenuItemsOrdering:self.menu];
    }
}

- (BOOL)handleOrderingTouchForItemView:(MenuItemView *)itemView withOtherItemView:(MenuItemView *)otherItemView touchLocation:(CGPoint)touchLocation
{
    // ordering may may reflect the user wanting to move an item to before or after otherItem
    // ordering may reflect the user wanting to move an item to be a child of the parent of otherItem
    // ordering may reflect the user wanting to move an item out of a child stack, or up the parent tree to the next parent

    if (itemView == otherItemView) {
        return NO;
    }

    MenuItem *item = itemView.item;
    MenuItem *otherItem = otherItemView.item;

    // can't order a ancestor within a descendant
    if ([otherItem isDescendantOfItem:item]) {
        return NO;
    }

    BOOL updated = NO;

    NSMutableOrderedSet *orderedItems = [NSMutableOrderedSet orderedSetWithOrderedSet:self.menu.items];

    const BOOL itemIsOrderedBeforeOtherItem = [orderedItems indexOfObject:item] < [orderedItems indexOfObject:otherItem];

    const BOOL orderingTouchesBeforeOtherItem = touchLocation.y < CGRectGetMidY(otherItemView.frame);
    const BOOL orderingTouchesAfterOtherItem = !orderingTouchesBeforeOtherItem; // using additional BOOL for readability

    void (^moveItemAndDescendantsOrderingWithOtherItem)(BOOL) = ^ (BOOL afterOtherItem) {

        // get the item and its descendants
        NSMutableArray *movingItems = [NSMutableArray array];
        for (NSUInteger i = [orderedItems indexOfObject:item]; i < orderedItems.count; i++) {
            MenuItem *orderedItem = [orderedItems objectAtIndex:i];
            if (orderedItem != item && ![orderedItem isDescendantOfItem:item]) {
                break;
            }
            [movingItems addObject:orderedItem];
        }

        [orderedItems removeObjectsInArray:movingItems];

        // insert the items in new position
        NSUInteger otherItemIndex = [orderedItems indexOfObject:otherItem];
        NSUInteger insertionIndex = afterOtherItem ? otherItemIndex + 1 : otherItemIndex;

        [orderedItems insertObjects:movingItems atIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(insertionIndex, movingItems.count)]];
    };

    if (itemIsOrderedBeforeOtherItem) {
        // descending in ordering

        if (orderingTouchesBeforeOtherItem) {
            // trying to move up the parent tree

            if (item.parent != otherItem.parent) {
                if ([self nextAvailableItemForOrderingAfterItem:item] == otherItem) {
                    // take the parent of the otherItem, or nil
                    item.parent = otherItem.parent;
                    updated = YES;
                }
            }

        } else  if (orderingTouchesAfterOtherItem) {
            // trying to order the item after the otherItem

            if (otherItem.children.count) {
                // if ordering after a parent, we need to become a child
                item.parent = otherItem;
            } else  {
                // assuming the item will take the parent of the otherItem's parent, or nil
                item.parent = otherItem.parent;
            }

            moveItemAndDescendantsOrderingWithOtherItem(YES);

            updated = YES;
        }

    } else  {
        // ascending in ordering

        if (orderingTouchesBeforeOtherItem) {
            // trying to order the item before the otherItem

            // assuming the item will become the parent of the otherItem's parent, or nil
            item.parent = otherItem.parent;

            moveItemAndDescendantsOrderingWithOtherItem(NO);

            updated = YES;

        } else  if (orderingTouchesAfterOtherItem) {
            // trying to become a child of the otherItem's parent

            if (item.parent != otherItem.parent) {

                // can't become a child of the otherItem's parent, if already a child of otherItem
                if (item.parent != otherItem) {
                    if ([self nextAvailableItemForOrderingBeforeItem:item] == otherItem) {
                        // become the parent of the otherItem's parent, or nil
                        item.parent = otherItem.parent;
                        updated = YES;
                    }
                }
            }
        }
    }

    if (updated) {

        // update the stackView arrangedSubviews ordering to reflect the ordering in orderedItems
        [self.stackView sendSubviewToBack:otherItemView];
        [self orderingAnimationWithBlock:^{
            for (NSUInteger i = 0; i < orderedItems.count; i++) {

                MenuItem *item = [orderedItems objectAtIndex:i];
                MenuItemView *itemView = [self itemViewForItem:item];
                [self.stackView insertArrangedSubview:itemView atIndex:i];
            }
        }];

        self.menu.items = orderedItems;
        [self.delegate itemsViewController:self didUpdateMenuItemsOrdering:self.menu];
    }

    return updated;
}

- (MenuItem *)nextAvailableItemForOrderingAfterItem:(MenuItem *)item
{
    MenuItem *availableItem = nil;
    NSUInteger itemIndex = [self.menu.items indexOfObject:item];

    for (NSUInteger i = itemIndex + 1; itemIndex < self.menu.items.count; i++) {

        MenuItem *anItem = [self.menu.items objectAtIndex:i];
        if (![anItem isDescendantOfItem:item]) {
            availableItem = anItem;
            break;
        }
    }

    return availableItem;
}

- (MenuItem *)nextAvailableItemForOrderingBeforeItem:(MenuItem *)item
{
    NSUInteger itemIndex = [self.menu.items indexOfObject:item];
    if (itemIndex == 0) {
        return nil;
    }

    MenuItem *availableItem = [self.menu.items objectAtIndex:itemIndex - 1];
    return availableItem;
}

- (void)toggleOrderingPlaceHolder:(BOOL)showsPlaceholder forItemViewsWithSelectedItemView:(MenuItemView *)selectedItemView
{
    selectedItemView.isPlaceholder = showsPlaceholder;

    if (!selectedItemView.item.children.count) {
        return;
    }

    // find any descendant MenuItemViews that should also be set as a placeholder or not
    NSArray *arrangedViews = self.stackView.arrangedSubviews;

    NSUInteger itemViewIndex = [arrangedViews indexOfObject:selectedItemView];
    for (NSUInteger i = itemViewIndex + 1; i < arrangedViews.count; i++) {
        UIView *view = [arrangedViews objectAtIndex:i];
        if ([view isKindOfClass:[MenuItemView class]]) {
            MenuItemView *itemView = (MenuItemView *)view;
            if ([itemView.item isDescendantOfItem:selectedItemView.item]) {
                itemView.isPlaceholder = showsPlaceholder;
            }
        }
    }
}

- (void)orderingAnimationWithBlock:(void(^)(void))block
{
    [UIView animateWithDuration:0.10 animations:^{
        block();
    } completion:nil];
}

- (void)prepareVisualOrderingViewWithItemView:(MenuItemView *)selectedItemView
{
    MenuItemsVisualOrderingView *orderingView = self.visualOrderingView;
    if (!orderingView) {
        orderingView = [[MenuItemsVisualOrderingView alloc] initWithFrame:self.stackView.bounds];
        orderingView.delegate = self;
        orderingView.translatesAutoresizingMaskIntoConstraints = NO;
        orderingView.backgroundColor = [UIColor clearColor];
        orderingView.userInteractionEnabled = NO;
        orderingView.hidden = YES;

        [self.view addSubview:orderingView];
        [NSLayoutConstraint activateConstraints:@[
                                                  [orderingView.topAnchor constraintEqualToAnchor:self.stackView.topAnchor],
                                                  [orderingView.leadingAnchor constraintEqualToAnchor:self.stackView.leadingAnchor],
                                                  [orderingView.trailingAnchor constraintEqualToAnchor:self.stackView.trailingAnchor],
                                                  [orderingView.bottomAnchor constraintEqualToAnchor:self.stackView.bottomAnchor]
                                                  ]];
        _visualOrderingView = orderingView;
    }

    [self.visualOrderingView setupVisualOrderingWithItemView:selectedItemView];
}

- (void)showVisualOrderingView
{
    self.visualOrderingView.hidden = NO;
}

- (void)hideVisualOrderingView
{
    self.visualOrderingView.hidden = YES;
}

#pragma mark - MenuItemsVisualOrderingViewDelegate

- (void)visualOrderingView:(MenuItemsVisualOrderingView *)visualOrderingView animatingVisualItemViewForOrdering:(MenuItemView *)orderingView
{
    [self.delegate itemsViewController:self prefersAdjustingScrollingOffsetForAnimatingView:orderingView];
}

#pragma mark - MenuItemViewDelegate

- (void)itemView:(MenuItemAbstractView *)itemView highlighted:(BOOL)highlighted
{
    // Toggle drawing the line separator on the previous view in the stackView.
    // Otherwise the drawn line stacks oddling against the highlighted drawing.
    NSUInteger indexOfView = [self.stackView.arrangedSubviews indexOfObject:itemView];
    if (indexOfView != NSNotFound && indexOfView > 0) {
        MenuItemAbstractView *view = [self.stackView.arrangedSubviews objectAtIndex:indexOfView - 1];
        if ([view isKindOfClass:[MenuItemAbstractView class]]) {
            view.drawsLineSeparator = !highlighted;
        }
    }
}

- (void)itemViewSelected:(MenuItemView *)itemView
{
    if (self.isEditingForItemViewInsertion) {
        [self removeItemInsertionViews:YES];
    }
    [self.delegate itemsViewController:self selectedItemForEditing:itemView.item];
}

- (void)itemViewAddButtonPressed:(MenuItemView *)itemView
{
    [self insertItemInsertionViewsAroundItemView:itemView animated:YES];
}

- (void)itemViewCancelButtonPressed:(MenuItemView *)itemView
{
    [self removeItemInsertionViews:YES];
}

#pragma mark - MenuItemInsertionViewDelegate

- (void)itemInsertionViewSelected:(MenuItemInsertionView *)insertionView
{
    dispatch_async(dispatch_get_main_queue(), ^{

        // Dispatch a bit later since we are about to swap out views.
        // Any layout or drawing related to the seleciton made need to complete before removing the insertionView.

        MenuItem *toggledItem = self.itemViewForInsertionToggling.item;

        // Create a new item.
        MenuItem *newItem = [NSEntityDescription insertNewObjectForEntityForName:[MenuItem entityName] inManagedObjectContext:self.menu.managedObjectContext];
        newItem.name = [MenuItem defaultItemNameLocalized];
        newItem.type = MenuItemTypePage;

        // Insert the new item into the menu's ordered items.
        BOOL requiresOffsetInsertionOrder = NO;
        NSMutableOrderedSet *orderedItems = [NSMutableOrderedSet orderedSetWithOrderedSet:self.menu.items];
        switch (insertionView.insertionOrder) {

            case MenuItemInsertionOrderAbove:
                [orderedItems insertObject:newItem atIndex:[orderedItems indexOfObject:toggledItem]];
                newItem.parent = toggledItem.parent;
                break;

            case MenuItemInsertionOrderBelow:
            {
                if (toggledItem.children.count) {
                    // Find the last child and insert below it.
                    MenuItem *lastChild = [toggledItem lastDescendantInOrderedItems:orderedItems];
                    [orderedItems insertObject:newItem atIndex:[orderedItems indexOfObject:lastChild] + 1];
                    requiresOffsetInsertionOrder = YES;
                } else {
                    [orderedItems insertObject:newItem atIndex:[orderedItems indexOfObject:toggledItem] + 1];
                }
                newItem.parent = toggledItem.parent;
                break;
            }

            case MenuItemInsertionOrderChild:
                [orderedItems insertObject:newItem atIndex:[orderedItems indexOfObject:toggledItem] + 1];
                newItem.parent = toggledItem;
                break;
        }

        // Update the menu items.
        self.menu.items = orderedItems;

        // Go ahead and save the context with the new item, we can delete later if needed.
        [[ContextManager sharedInstance] saveContextAndWait:self.menu.managedObjectContext];

        // Add and replace the insertionView with a new itemView.
        MenuItemView *newItemView = [self addNewItemViewWithItem:newItem];
        if (requiresOffsetInsertionOrder) {
            // Need to find the correct index for the new itemView.
            MenuItem *previousItem = [orderedItems objectAtIndex:[orderedItems indexOfObject:newItem] - 1];
            MenuItemView *previousItemView = [self itemViewForItem:previousItem];
            [self.stackView insertArrangedSubview:newItemView atIndex:[self.stackView.arrangedSubviews indexOfObject:previousItemView] + 1];
        } else {
            // Easily swap out the insertionView with the new itemView.
            [self.stackView insertArrangedSubview:newItemView atIndex:[self.stackView.arrangedSubviews indexOfObject:insertionView]];
            [self.stackView removeArrangedSubview:insertionView];
            [insertionView removeFromSuperview];
        }
        [self removeItemInsertionViews:YES];

        // Inform the delegate to begin editing the new item.
        [self.delegate itemsViewController:self createdNewItemForEditing:newItem];
    });
}

#pragma mark - Ordering Taptic Feedback

- (void)prepareOrderingFeedbackGenerator
{
    self.orderingFeedbackGenerator = [UISelectionFeedbackGenerator new];
    [self.orderingFeedbackGenerator prepare];
}

- (void)triggerOrderingFeedbackGenerator
{
    [self.orderingFeedbackGenerator selectionChanged];
    [self.orderingFeedbackGenerator prepare];
}

- (void)cleanUpOrderingFeedbackGenerator
{
    self.orderingFeedbackGenerator = nil;
}

@end
