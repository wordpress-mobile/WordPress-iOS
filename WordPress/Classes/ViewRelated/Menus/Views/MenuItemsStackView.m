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
@property (nonatomic, strong) MenuItemView *activeItemView;

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
    self.activeItemView = toggledItemView;
    
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
    
    self.activeItemView = nil;
}

- (void)removeItemInsertionViews:(BOOL)animated
{
    if(!animated) {
        [self removeItemInsertionViews];
        return;
    }
    
    CGRect previousRect = self.activeItemView.frame;
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

#pragma mark - MenuItemsStackableViewDelegate

- (void)itemsStackableViewDidBeginReordering:(MenuItemsStackableView *)stackableView
{
    [self.delegate itemsView:self prefersScrollingEnabled:NO];
}

- (void)itemsStackableView:(MenuItemsStackableView *)stackableView orderingTouchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event vector:(CGPoint)vector
{
    if(![stackableView isKindOfClass:[MenuItemsStackableView class]]) {
        return;
    }

    const CGPoint touchPoint = [[touches anyObject] locationInView:self];
    MenuItemView *selectedItemView = (MenuItemView *)stackableView;
    
    // index of the itemView in the arrangedSubViews list
    const NSUInteger selectedItemViewIndex = [self.stackView.arrangedSubviews indexOfObject:selectedItemView];
    
    //// horiztonal indentation detection (child relationships)
    //// detect if the user is moving horizontally to the right or left to change the indentation
    
    // first check to see if we should pay attention to touches that might signal a change in indentation
    const BOOL detectedHorizontalIndentationTouches = fabs(vector.x) > ((selectedItemView.frame.size.width * 5.0) / 100); // a travel of x% should be considered
    const BOOL detectedVerticalIndentationTouches = fabs(vector.y) > ((selectedItemView.frame.size.height * 20.0) / 100); // a travel of y% should be considered

    if(detectedHorizontalIndentationTouches || detectedVerticalIndentationTouches) {
     
        // look for any itemViews that might be above the selectedItemView
        MenuItemView *itemViewAboveSelected = [self arrangedItemViewAboveItemView:selectedItemView];
        
        // if there is an itemView above the selectedItemView, check for touches signaling a change in indentation
        if(itemViewAboveSelected && detectedHorizontalIndentationTouches) {
            if(vector.x > 0) {
                // more indentation
                NSInteger indentation = selectedItemView.indentationLevel + 1;
                const NSInteger maxIndentation = itemViewAboveSelected.indentationLevel + 1;
                if(indentation > maxIndentation) {
                    indentation = maxIndentation;
                }
                selectedItemView.indentationLevel = indentation;
            }else {
                // less indentation
                NSInteger indentation = selectedItemView.indentationLevel - 1;
                if(indentation < 0) {
                    indentation = 0;
                }
                selectedItemView.indentationLevel = indentation;
            }
        }
        
        if(detectedVerticalIndentationTouches) {
            
            if(vector.y < 0) {
                
                if(!itemViewAboveSelected) {
                    selectedItemView.indentationLevel = 0;
                }else {
                    if(selectedItemView.indentationLevel < itemViewAboveSelected.indentationLevel) {
                        selectedItemView.indentationLevel = itemViewAboveSelected.indentationLevel;
                    }
                }
                
            }else {
                
                MenuItemView *itemViewBelowSelected = [self arrangedItemViewBelowItemView:selectedItemView];
                if(!itemViewBelowSelected) {
                    selectedItemView.indentationLevel = 0;
                }else {
                    if(selectedItemView.indentationLevel > itemViewBelowSelected.indentationLevel) {
                        selectedItemView.indentationLevel = itemViewBelowSelected.indentationLevel;
                    }
                }
            }
        }
        
        // reset the vector to observe the next delta of interest
        [selectedItemView resetOrderingTouchesMovedVector];
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
                
                selectedItemView.indentationLevel = itemView.indentationLevel;
                [self.stackView bringSubviewToFront:selectedItemView];
                
                [UIView animateWithDuration:0.15 animations:^{
                    // update the index of the itemView to the index of the selectedItemView to perform a swap
                    [self.stackView insertArrangedSubview:itemView atIndex:selectedItemViewIndex];
                }];
                break;
            }
        }
    }
}

- (void)itemsStackableViewDidEndReordering:(MenuItemsStackableView *)stackableView
{
    [self.delegate itemsView:self prefersScrollingEnabled:YES];
}

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
