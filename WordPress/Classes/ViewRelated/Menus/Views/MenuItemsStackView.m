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
@property (nonatomic, assign) BOOL isOrdering;
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

- (MenuItemView *)arrangedItemViewAboveItemView:(MenuItemView *)subjectItemView
{
    MenuItemView *itemViewAbove = nil;
    for(UIView *arrangedView in self.stackView.arrangedSubviews) {
        // ignore any other views that aren't itemViews
        if(![arrangedView isKindOfClass:[MenuItemView class]]) {
            continue;
        }
        if(arrangedView == subjectItemView) {
            break;
        }
        itemViewAbove = (MenuItemView *)arrangedView;
    }
    
    return itemViewAbove;
}

- (MenuItemView *)arrangedItemViewBelowItemView:(MenuItemView *)subjectItemView
{
    MenuItemView *itemViewBelow = nil;
    for(UIView *arrangedView in [self.stackView.arrangedSubviews reverseObjectEnumerator]) {
        // ignore any other views that aren't itemViews
        if(![arrangedView isKindOfClass:[MenuItemView class]]) {
            continue;
        }
        if(arrangedView == subjectItemView) {
            break;
        }
        itemViewBelow = (MenuItemView *)arrangedView;
    }
    
    return itemViewBelow;
}

#pragma mark - touches

- (void)resetTouchesMovedObservationVector
{
    self.touchesBeganLocation = self.touchesMovedLocation;
}

- (void)updateWithTouchesStarted:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    self.touchesBeganLocation = [[touches anyObject] locationInView:self];
}

- (void)updateWithTouchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    CGPoint location = [[touches anyObject] locationInView:self];
    
    if(!self.isOrdering) {
        for(MenuItemView *itemView in self.itemViews) {
            if(CGRectContainsPoint(itemView.frame, location)) {
                [self beginOrdering:itemView];
                break;
            }
        }
    }else {
        
        CGPoint startLocation = self.touchesBeganLocation;
        self.touchesMovedLocation = location;
        CGPoint vector = CGPointZero;
        vector.x = location.x - startLocation.x;
        vector.y = location.y - startLocation.y;
        
        [self orderingTouchesMoved:touches withEvent:event vector:vector];
    }
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
    self.isOrdering = YES;
    self.itemViewForOrdering = orderingView;
    orderingView.isPlaceholder = YES;
    
    [self.delegate itemsView:self prefersScrollingEnabled:NO];
}

- (void)orderingTouchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event vector:(CGPoint)vector
{
    const CGPoint touchPoint = [[touches anyObject] locationInView:self];
    MenuItemView *selectedItemView = self.itemViewForOrdering;
    MenuItem *selectedItem = selectedItemView.item;
    
    // index of the itemView in the arrangedSubViews list
//    const NSUInteger selectedItemViewIndex = [self.stackView.arrangedSubviews indexOfObject:selectedItemView];
    
    //// horiztonal indentation detection (child relationships)
    //// detect if the user is moving horizontally to the right or left to change the indentation
    
    // first check to see if we should pay attention to touches that might signal a change in indentation
    const BOOL detectedHorizontalOrderingTouches = fabs(vector.x) > ((selectedItemView.frame.size.width * 5.0) / 100); // a travel of x% should be considered
    BOOL modelUpdated = NO;
    
    if(detectedHorizontalOrderingTouches) {
        
        NSOrderedSet *orderedItems = self.menu.items;
        NSUInteger selectedItemIndex = [orderedItems indexOfObject:selectedItem];
        
        // check if not first item in order
        if(selectedItemIndex > 0) {
            // detect the child/parent relationship changes and update the model
            if(vector.x > 0) {
                // trying to make a child
                MenuItem *previousItem = nil;
                for(MenuItem *item in orderedItems) {
                    if(item == selectedItem) {
                        break;
                    }
                    previousItem = item;
                }
                MenuItem *parent = previousItem;
                MenuItem *newParent = nil;
                while (parent && parent != selectedItem.parent) {
                    newParent = parent;
                    parent = parent.parent;
                }
                
                if(newParent) {
                    selectedItem.parent = newParent;
                    modelUpdated = YES;
                }
                
            }else {
                if(selectedItem.parent) {
                    
                    MenuItem *lastChildItem = nil;
                    for(MenuItem *item in orderedItems) {
                        // find the lastChildItem of the parent
                        if(item.parent != selectedItem.parent) {
                            continue;
                        }
                        lastChildItem = item;
                    }
                    
                    // only the lastChildItem can move up the tree, otherwise it would break the visual child/parent relationship
                    if(selectedItem == lastChildItem) {
                        // try to move up the parent tree
                        MenuItem *parent = selectedItem.parent.parent;
                        selectedItem.parent = parent;
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
                
                // reorder the model
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

- (void)endReordering
{
    self.isOrdering = NO;
    self.itemViewForOrdering.isPlaceholder = NO;
    self.itemViewForOrdering = nil;
    
    [self.delegate itemsView:self prefersScrollingEnabled:YES];
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
