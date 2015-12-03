#import "MenuItemsStackView.h"
#import "Menu.h"
#import "MenuItem.h"
#import "WPStyleGuide.h"
#import "MenuItemsStackableView.h"
#import "MenuItemView.h"
#import "MenuItemInsertionView.h"
#import "MenusDesign.h"

@interface MenuItemsStackView () <MenuItemsStackableViewDelegate, MenuItemViewDelegate, MenuItemInsertionViewDelegate>

@property (nonatomic, weak) IBOutlet UIStackView *stackView;
@property (nonatomic, strong) NSMutableSet *itemViews;

@property (nonatomic, strong) NSMutableSet *insertionViews;
@property (nonatomic, strong) MenuItemView *itemViewForInsertionToggling;

@property (nonatomic, assign) CGPoint touchesBeganLocation;
@property (nonatomic, assign) CGPoint touchesMovedLocation;
@property (nonatomic, assign) BOOL touchesOrdering;
@property (nonatomic, strong) MenuItemView *itemViewForOrdering;

@end

@implementation MenuItemsStackView

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
    self.backgroundColor = [WPStyleGuide lightGrey];
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
    for(MenuItemsStackableView *itemView in self.stackView.arrangedSubviews) {
        [self.stackView removeArrangedSubview:itemView];
        [itemView removeFromSuperview];
    }
    
    self.itemViews = [NSMutableSet set];
    self.insertionViews = nil;
    
    MenuItemView *lastItemView = nil;
    for(MenuItem *item in self.menu.items) {
        
        MenuItemView *itemView = [[MenuItemView alloc] init];
        itemView.delegate = self;
        // set up ordering to help with any drawing
        itemView.item = item;
        itemView.indentationLevel = 0;
        
        MenuItem *parentItem = item.parent;
        while (parentItem) {
            itemView.indentationLevel++;
            parentItem = parentItem.parent;
        }
        
        NSLayoutConstraint *heightConstraint = [itemView.heightAnchor constraintEqualToConstant:MenuItemsStackableViewDefaultHeight];
        heightConstraint.priority = UILayoutPriorityDefaultHigh;
        heightConstraint.active = YES;
        
        [self.itemViews addObject:itemView];
        [self.stackView addArrangedSubview:itemView];
        
        [itemView.widthAnchor constraintEqualToAnchor:self.widthAnchor].active = YES;
        lastItemView = itemView;
    }
}

- (MenuItemInsertionView *)addNewInsertionViewWithType:(MenuItemInsertionViewType)type forItemView:(MenuItemView *)itemView
{
    NSInteger index = [self.stackView.arrangedSubviews indexOfObject:itemView];
    MenuItemInsertionView *insertionView = [[MenuItemInsertionView alloc] init];
    insertionView.delegate = self;
    insertionView.type = type;
    
    switch (type) {
        case MenuItemInsertionViewTypeAbove:
            insertionView.indentationLevel = itemView.indentationLevel;
            break;
        case MenuItemInsertionViewTypeBelow:
            insertionView.indentationLevel = itemView.indentationLevel;
            index++;
            break;
        case MenuItemInsertionViewTypeChild:
            insertionView.indentationLevel = itemView.indentationLevel + 1;
            index += 2;
            break;
    }
    
    NSLayoutConstraint *heightConstraint = [insertionView.heightAnchor constraintEqualToConstant:MenuItemsStackableViewDefaultHeight];
    heightConstraint.priority = UILayoutPriorityDefaultHigh;
    heightConstraint.active = YES;
    
    [self.insertionViews addObject:insertionView];
    [self.stackView insertArrangedSubview:insertionView atIndex:index];
    
    [insertionView.widthAnchor constraintEqualToAnchor:self.stackView.widthAnchor].active = YES;
    
    return insertionView;
}

- (void)insertInsertionItemViewsAroundItemView:(MenuItemView *)toggledItemView
{
    self.itemViewForInsertionToggling = toggledItemView;
    
    self.insertionViews = [NSMutableSet setWithCapacity:3];
    [self addNewInsertionViewWithType:MenuItemInsertionViewTypeAbove forItemView:toggledItemView];
    [self addNewInsertionViewWithType:MenuItemInsertionViewTypeBelow forItemView:toggledItemView];
    [self addNewInsertionViewWithType:MenuItemInsertionViewTypeChild forItemView:toggledItemView];
}

- (void)insertItemInsertionViewsAroundItemView:(MenuItemView *)toggledItemView animated:(BOOL)animated
{
    CGRect previousRect = toggledItemView.frame;
    CGRect updatedRect = toggledItemView.frame;
    
    [self insertInsertionItemViewsAroundItemView:toggledItemView];
    
    if(!animated) {
        return;
    }
    
    // since we are adding content above the toggledItemView, the toggledItemView (focus) will move downwards with the updated content size
    updatedRect.origin.y += MenuItemsStackableViewDefaultHeight;
    
    for(MenuItemInsertionView *insertionView in self.insertionViews) {
        insertionView.hidden = YES;
        insertionView.alpha = 0.0;
    }
    
    [UIView animateWithDuration:0.3 delay:0.0 options:0 animations:^{
        
        for(MenuItemInsertionView *insertionView in self.insertionViews) {
            insertionView.hidden = NO;
            insertionView.alpha = 1.0;
        }
        
        // inform the delegate to handle this content change based on the rect we are focused on
        // a delegate will likely scroll the content with the size change
        [self.delegate itemsViewAnimatingContentSizeChanges:self focusedRect:previousRect updatedFocusRect:updatedRect];
        
    } completion:^(BOOL finished) {
        
    }];
}

- (void)removeItemInsertionViews
{
    for(MenuItemInsertionView *insertionView in self.insertionViews) {
        [self.stackView removeArrangedSubview:insertionView];
        [insertionView removeFromSuperview];
    }
    
    self.insertionViews = nil;
    [self.stackView setNeedsLayout];
    
    self.itemViewForInsertionToggling = nil;
}

- (void)removeItemInsertionViews:(BOOL)animated
{
    if(!animated) {
        [self removeItemInsertionViews];
        return;
    }
    
    CGRect previousRect = self.itemViewForInsertionToggling.frame;
    CGRect updatedRect = previousRect;
    // since we are removing content above the toggledItemView, the toggledItemView (focus) will move upwards with the updated content size
    updatedRect.origin.y -= MenuItemsStackableViewDefaultHeight;
    
    [UIView animateWithDuration:0.3 delay:0.0 options:0 animations:^{
        
        for(MenuItemInsertionView *insertionView in self.insertionViews) {
            insertionView.hidden = YES;
            insertionView.alpha = 0.0;
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
    for(MenuItemView *arrangedItemView in self.itemViews) {
        if(arrangedItemView.item == item) {
            itemView = arrangedItemView;
            break;
        }
    }
    return itemView;
}

#pragma mark - touches

- (void)resetTouchesMovedObservationVector
{
    self.touchesBeganLocation = self.touchesMovedLocation;
}

- (void)updateWithTouchesStarted:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    CGPoint location = [[touches anyObject] locationInView:self];

    self.touchesBeganLocation = location;
    for(MenuItemView *itemView in self.itemViews) {
        if(CGRectContainsPoint(itemView.frame, location)) {
            [self beginOrdering:itemView];
            break;
        }
    }
}

- (void)updateWithTouchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    CGPoint location = [[touches anyObject] locationInView:self];
    
    CGPoint startLocation = self.touchesBeganLocation;
    self.touchesMovedLocation = location;
    CGPoint vector = CGPointZero;
    vector.x = location.x - startLocation.x;
    vector.y = location.y - startLocation.y;
    
    [self orderingTouchesMoved:touches withEvent:event vector:vector];
}

- (void)updateWithTouchesStopped:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
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
    self.touchesOrdering = YES;
    
    self.itemViewForOrdering = orderingView;
    [self toggleOrderingPlaceHolder:YES forItemViewsWithSelectedItemView:orderingView];
    
    [self.delegate itemsView:self prefersScrollingEnabled:NO];
}

- (void)endReordering
{
    // cleanup
    
    self.touchesOrdering = NO;
    
    [self toggleOrderingPlaceHolder:NO forItemViewsWithSelectedItemView:self.itemViewForOrdering];
    self.itemViewForOrdering = nil;

    [self.delegate itemsView:self prefersScrollingEnabled:YES];
}

- (void)orderingTouchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event vector:(CGPoint)vector
{    
    const CGPoint touchPoint = [[touches anyObject] locationInView:self];
    MenuItemView *selectedItemView = self.itemViewForOrdering;
    
    MenuItem *selectedItem = selectedItemView.item;
    
    //// horiztonal indentation detection (child relationships)
    //// detect if the user is moving horizontally to the right or left to change the indentation
    
    // first check to see if we should pay attention to touches that might signal a change in indentation
    const BOOL detectedHorizontalOrderingTouches = fabs(vector.x) > ((selectedItemView.frame.size.width * 5.0) / 100); // a travel of x% should be considered for updating relationships
    BOOL modelUpdated = NO;
    
    if(detectedHorizontalOrderingTouches) {
        
        NSOrderedSet *orderedItems = self.menu.items;
        NSUInteger selectedItemIndex = [orderedItems indexOfObject:selectedItem];
        
        // check if not first item in order
        if(selectedItemIndex > 0) {
            // detect the child/parent relationship changes and update the model
            if(vector.x > 0) {
                // trying to make a child
                MenuItem *previousItem = [orderedItems objectAtIndex:selectedItemIndex - 1];
                MenuItem *parent = previousItem;
                MenuItem *newParent = nil;
                while (parent) {
                    if(parent == selectedItem.parent) {
                        break;
                    }
                    newParent = parent;
                    parent = parent.parent;
                }
                
                if(newParent) {
                    selectedItem.parent = newParent;
                    NSLog(@">>>>> newparent: %@", selectedItem.parent.name);
                    modelUpdated = YES;
                }
                
            }else {
                if(selectedItem.parent) {
                    
                    MenuItem *lastChildItem = nil;
                    NSUInteger parentIndex = [orderedItems indexOfObject:selectedItem.parent];
                    for(NSUInteger i = parentIndex + 1; i < orderedItems.count; i++) {
                        MenuItem *child = [orderedItems objectAtIndex:i];
                        if(child.parent == selectedItem.parent) {
                            lastChildItem = child;
                        }
                        if(![lastChildItem isDescendantOfItem:selectedItem.parent]) {
                            break;
                        }
                    }
                    NSLog(@"lastChildItem: %@", lastChildItem.name);
                    
                    // only the lastChildItem can move up the tree, otherwise it would break the visual child/parent relationship
                    if(selectedItem == lastChildItem) {
                        // try to move up the parent tree
                        MenuItem *parent = selectedItem.parent.parent;
                        selectedItem.parent = parent;
                        NSLog(@"<<<<< newparent: %@", selectedItem.parent.name);
                        modelUpdated = YES;
                    }
                }
            }
        }
        
        // reset the vector to observe the next delta of interest
        [self resetTouchesMovedObservationVector];
    }
    
    if(!CGRectContainsPoint(selectedItemView.frame, touchPoint)) {
        
        //// if the touch is over a different item, detect which item to replace the ordering with
        
        for(MenuItemView *itemView in self.itemViews) {
            // enumerate the itemViews lists since we don't care about other views in the stackView.arrangedSubviews list
            if(itemView == selectedItemView) {
                continue;
            }
            // detect if the touch within a padded inset of an itemView under the touchPoint
            const CGRect orderingDetectionRect = CGRectInset(itemView.frame, 10.0, 10.0);
            if(CGRectContainsPoint(orderingDetectionRect, touchPoint)) {
                
                // reorder the model if needed or available
                BOOL orderingUpdate = [self handleOrderingTouchForItemView:selectedItemView withOtherItemView:itemView touchLocation:touchPoint];
                if(orderingUpdate) {
                    modelUpdated = YES;
                }
                break;
            }
        }
    }
    
    // update the views based on the model changes
    if(modelUpdated) {
        
        for(UIView *arrangedView in self.stackView.arrangedSubviews) {
            if(![arrangedView isKindOfClass:[MenuItemView class]]) {
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
}

- (BOOL)handleOrderingTouchForItemView:(MenuItemView *)itemView withOtherItemView:(MenuItemView *)otherItemView touchLocation:(CGPoint)touchLocation
{
    // ordering may may reflect the user wanting to move an item to before or after otherItem
    // ordering may reflect the user wanting to move an item to be a child of the parent of otherItem
    // ordering may reflect the user wanting to move an item out of a child stack, or up the parent tree to the next parent
    
    if(itemView == otherItemView) {
        return NO;
    }
    
    MenuItem *item = itemView.item;
    MenuItem *otherItem = otherItemView.item;

    // can't order a ancestor within a descendant
    if([otherItem isDescendantOfItem:item]) {
        return NO;
    }
    
    BOOL updated = NO;
    
    NSMutableOrderedSet *orderedItems = [NSMutableOrderedSet orderedSetWithOrderedSet:self.menu.items];
    
    const BOOL itemIsOrderedBeforeOtherItem = [orderedItems indexOfObject:item] < [orderedItems indexOfObject:otherItem];
    
    const BOOL orderingTouchesBeforeOtherItem = touchLocation.y < CGRectGetMidY(otherItemView.frame);
    const BOOL orderingTouchesAfterOtherItem = !orderingTouchesBeforeOtherItem; // using additional BOOL for readability
    
    // check to make sure we're only trying to order items based on the order they occur
    // prevents touches that skip around the screen and break the ordering by ordering with an otherItem not adjacent to the item
    if(itemIsOrderedBeforeOtherItem) {
        if(orderingTouchesAfterOtherItem) {
            if([self nextAvailableItemForOrderingAfterItem:item] != otherItem) {
                return NO;
            }
        }
    }else {
        if(orderingTouchesBeforeOtherItem) {
            if([self nextAvailableItemForOrderingBeforeItem:item] != otherItem) {
                return NO;
            }
        }
    }
    
    if(itemIsOrderedBeforeOtherItem) {
        // descending in ordering
        
        if(orderingTouchesBeforeOtherItem) {
            // trying to move up the parent tree
            
            if(item.parent != otherItem.parent) {
                if([self nextAvailableItemForOrderingAfterItem:item] == otherItem) {
                    // take the parent of the otherItem, or nil
                    item.parent = otherItem.parent;
                    updated = YES;
                }
            }
            
        }else if(orderingTouchesAfterOtherItem) {
            // trying to order the item after the otherItem
            
            if(otherItem.children.count) {
                // if ordering after a parent, we need to become a child
                item.parent = otherItem;
            }else {
                // assuming the item will take the parent of the otherItem's parent, or nil
                item.parent = otherItem.parent;
            }
            
            [orderedItems removeObject:otherItem];
            [orderedItems insertObject:otherItem atIndex:[orderedItems indexOfObject:item]];
            
            // update the stackView arrangedSubviews ordering
            [self.stackView sendSubviewToBack:otherItemView];
            [self orderingAnimationWithBlock:^{
                NSUInteger exchangeItemViewIndex = [[self.stackView arrangedSubviews] indexOfObject:itemView];
                [self.stackView insertArrangedSubview:otherItemView atIndex:exchangeItemViewIndex];
            }];
            
            updated = YES;
        }
        
    }else {
        // ascending in ordering
        
        if(orderingTouchesBeforeOtherItem) {
            // trying to order the item before the otherItem
            
            // assuming the item will become the parent of the otherItem's parent, or nil
            item.parent = otherItem.parent;
            
            [orderedItems removeObject:otherItem];
            
            MenuItemView *itemViewForExchangingInStackView = nil;
            
            if(item.children.count) {
                // if item has children, move the otherItem to ordered after the last descendant of the item
                MenuItem *lastDescendant = item;
                
                NSUInteger itemIndex = [orderedItems indexOfObject:item];
                for(NSUInteger i = itemIndex + 1; i < orderedItems.count; i++) {
                    MenuItem *anItem = [orderedItems objectAtIndex:i];
                    if(![anItem isDescendantOfItem:item]) {
                        break;
                    }
                    
                    lastDescendant = anItem;
                }
                
                [orderedItems insertObject:otherItem atIndex:[orderedItems indexOfObject:lastDescendant] + 1];
                itemViewForExchangingInStackView = [self itemViewForItem:lastDescendant];

            }else {
                // move the otherItem to be ordered after the item
                [orderedItems insertObject:otherItem atIndex:[orderedItems indexOfObject:item] + 1];
                itemViewForExchangingInStackView = itemView;
            }
            
            // update the stackView arrangedSubviews ordering
            [self.stackView sendSubviewToBack:otherItemView];
            [self orderingAnimationWithBlock:^{
                NSUInteger exchangeItemViewIndex = [[self.stackView arrangedSubviews] indexOfObject:itemViewForExchangingInStackView];
                [self.stackView insertArrangedSubview:otherItemView atIndex:exchangeItemViewIndex];
            }];
            
            updated = YES;
            
        }else if(orderingTouchesAfterOtherItem) {
            // trying to become a child of the otherItem's parent
            
            if(item.parent != otherItem.parent) {
                
                // can't become a child of the otherItem's parent, if already a child of otherItem
                if(item.parent != otherItem) {
                    if([self nextAvailableItemForOrderingBeforeItem:item] == otherItem) {
                        // become the parent of the otherItem's parent, or nil
                        item.parent = otherItem.parent;
                        updated = YES;
                    }
                }
            }
        }
    }
    
    if(updated) {
        self.menu.items = orderedItems;
    }
    
    return updated;
}

- (MenuItem *)nextAvailableItemForOrderingAfterItem:(MenuItem *)item
{
    MenuItem *availableItem = nil;
    NSUInteger itemIndex = [self.menu.items indexOfObject:item];
    
    for(NSUInteger i = itemIndex + 1; itemIndex < self.menu.items.count; i++) {
        
        MenuItem *anItem = [self.menu.items objectAtIndex:i];
        if(![anItem isDescendantOfItem:item]) {
            availableItem = anItem;
            break;
        }
    }
    
    return availableItem;
}

- (MenuItem *)nextAvailableItemForOrderingBeforeItem:(MenuItem *)item
{
    NSUInteger itemIndex = [self.menu.items indexOfObject:item];
    if(itemIndex == 0) {
        return nil;
    }
    
    MenuItem *availableItem = [self.menu.items objectAtIndex:itemIndex - 1];
    return availableItem;
}

- (void)toggleOrderingPlaceHolder:(BOOL)showsPlaceholder forItemViewsWithSelectedItemView:(MenuItemView *)selectedItemView
{
    selectedItemView.isPlaceholder = showsPlaceholder;
    
    if(!selectedItemView.item.children.count) {
        return;
    }
    
    // find any descendant MenuItemViews that should also be set as a placeholder or not
    NSArray *arrangedViews = self.stackView.arrangedSubviews;
    
    NSUInteger itemViewIndex = [arrangedViews indexOfObject:selectedItemView];
    for(NSUInteger i = itemViewIndex + 1; i < arrangedViews.count; i++) {
        UIView *view = [arrangedViews objectAtIndex:i];
        if([view isKindOfClass:[MenuItemView class]]) {
            MenuItemView *itemView = (MenuItemView *)view;
            if([itemView.item isDescendantOfItem:selectedItemView.item]) {
                itemView.isPlaceholder = showsPlaceholder;
            }
        }
    }
}

- (void)orderingAnimationWithBlock:(void(^)())block
{
    [UIView animateWithDuration:0.10 animations:^{
        block();
    } completion:nil];
}


#pragma mark - MenuItemsStackableViewDelegate

#pragma mark - MenuItemViewDelegate

- (void)itemViewAddButtonPressed:(MenuItemView *)itemView
{
    itemView.showsCancelButtonOption = YES;
    for(MenuItemView *childItemView in self.itemViews) {
        childItemView.showsEditingButtonOptions = NO;
    }
    [self insertItemInsertionViewsAroundItemView:itemView animated:YES];
}

- (void)itemViewCancelButtonPressed:(MenuItemView *)itemView
{
    itemView.showsCancelButtonOption = NO;
    for(MenuItemView *childItemView in self.itemViews) {
        childItemView.showsEditingButtonOptions = YES;
    }
    [self removeItemInsertionViews:YES];
}

#pragma mark - MenuItemInsertionViewDelegate

- (void)itemInsertionViewSelected:(MenuItemInsertionView *)insertionView
{
    // load the detail view for creating a new item
}

@end