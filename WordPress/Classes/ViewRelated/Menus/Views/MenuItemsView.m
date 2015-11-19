#import "MenuItemsView.h"
#import "Menu.h"
#import "MenuItem.h"
#import "WPStyleGuide.h"
#import "MenuItemActionableView.h"
#import "MenuItemView.h"
#import "MenuItemPlaceholderView.h"
#import "MenusDesign.h"

@interface MenuItemsView () <MenuItemActionableViewDelegate, MenuItemViewDelegate, MenuItemPlaceholderViewDelegate>

@property (nonatomic, weak) IBOutlet UIStackView *stackView;
@property (nonatomic, strong) NSMutableSet *itemViews;
@property (nonatomic, strong) NSMutableSet *placeholderViews;
@property (nonatomic, strong) MenuItemView *activeItemView;

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
    for(MenuItemActionableView *itemView in self.stackView.arrangedSubviews) {
        [self.stackView removeArrangedSubview:itemView];
        [itemView removeFromSuperview];
    }
    
    self.itemViews = [NSMutableSet set];
    self.placeholderViews = nil;
    
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
        
        NSLayoutConstraint *heightConstraint = [itemView.heightAnchor constraintEqualToConstant:MenuItemActionableViewDefaultHeight];
        heightConstraint.priority = UILayoutPriorityDefaultHigh;
        heightConstraint.active = YES;
        
        [self.itemViews addObject:itemView];
        [self.stackView addArrangedSubview:itemView];
        
        [itemView.widthAnchor constraintEqualToAnchor:self.widthAnchor].active = YES;
        lastItemView = itemView;
    }
}

- (MenuItemPlaceholderView *)addNewPlaceholderViewWithType:(MenuItemPlaceholderViewType)type forItemView:(MenuItemView *)itemView
{
    NSInteger index = [self.stackView.arrangedSubviews indexOfObject:itemView];
    MenuItemPlaceholderView *placeholderView = [[MenuItemPlaceholderView alloc] init];
    placeholderView.delegate = self;
    placeholderView.type = type;
    
    switch (type) {
        case MenuItemPlaceholderViewTypeAbove:
            placeholderView.indentationLevel = itemView.indentationLevel;
            break;
        case MenuItemPlaceholderViewTypeBelow:
            placeholderView.indentationLevel = itemView.indentationLevel;
            index++;
            break;
        case MenuItemPlaceholderViewTypeChild:
            placeholderView.indentationLevel = itemView.indentationLevel + 1;
            index += 2;
            break;
    }

    NSLayoutConstraint *heightConstraint = [placeholderView.heightAnchor constraintEqualToConstant:MenuItemActionableViewDefaultHeight];
    heightConstraint.priority = UILayoutPriorityDefaultHigh;
    heightConstraint.active = YES;
    
    [self.placeholderViews addObject:placeholderView];
    [self.stackView insertArrangedSubview:placeholderView atIndex:index];
    
    [placeholderView.widthAnchor constraintEqualToAnchor:self.stackView.widthAnchor].active = YES;
    
    return placeholderView;
}

- (void)insertPlaceholderItemViewsAroundItemView:(MenuItemView *)toggledItemView
{
    self.activeItemView = toggledItemView;
    
    self.placeholderViews = [NSMutableSet setWithCapacity:3];
    [self addNewPlaceholderViewWithType:MenuItemPlaceholderViewTypeAbove forItemView:toggledItemView];
    [self addNewPlaceholderViewWithType:MenuItemPlaceholderViewTypeBelow forItemView:toggledItemView];
    [self addNewPlaceholderViewWithType:MenuItemPlaceholderViewTypeChild forItemView:toggledItemView];
}

- (void)insertItemPlaceholderViewsAroundItemView:(MenuItemView *)toggledItemView animated:(BOOL)animated
{
    CGRect previousRect = toggledItemView.frame;
    CGRect updatedRect = toggledItemView.frame;
    
    [self insertPlaceholderItemViewsAroundItemView:toggledItemView];
    
    if(!animated) {
        return;
    }
    
    // since we are adding content above the toggledItemView, the toggledItemView (focus) will move downwards with the updated content size
    updatedRect.origin.y += MenuItemActionableViewDefaultHeight;
    
    for(MenuItemPlaceholderView *placeholderView in self.placeholderViews) {
        placeholderView.hidden = YES;
        placeholderView.alpha = 0.0;
    }
    
    [UIView animateWithDuration:0.3 delay:0.0 options:0 animations:^{
        
        for(MenuItemPlaceholderView *placeholderView in self.placeholderViews) {
            placeholderView.hidden = NO;
            placeholderView.alpha = 1.0;
        }
        
        // inform the delegate to handle this content change based on the rect we are focused on
        // a delegate will likely scroll the content with the size change
        [self.delegate itemsViewAnimatingContentSizeChanges:self focusedRect:previousRect updatedFocusRect:updatedRect];
        
    } completion:^(BOOL finished) {
        
    }];
}

- (void)removeItemPlaceholderViews
{
    for(MenuItemActionableView *itemView in self.placeholderViews) {
        [self.stackView removeArrangedSubview:itemView];
        [itemView removeFromSuperview];
    }
    
    self.placeholderViews = nil;
    [self.stackView setNeedsLayout];
    
    self.activeItemView = nil;
}

- (void)removeItemPlaceholderViews:(BOOL)animated
{
    if(!animated) {
        [self removeItemPlaceholderViews];
        return;
    }
    
    CGRect previousRect = self.activeItemView.frame;
    CGRect updatedRect = previousRect;
    // since we are removing content above the toggledItemView, the toggledItemView (focus) will move upwards with the updated content size
    updatedRect.origin.y -= MenuItemActionableViewDefaultHeight;
    
    [UIView animateWithDuration:0.3 delay:0.0 options:0 animations:^{
       
        for(MenuItemPlaceholderView *placeholderView in self.placeholderViews) {
            placeholderView.hidden = YES;
            placeholderView.alpha = 0.0;
        }
        
        // inform the delegate to handle this content change based on the rect we are focused on
        // a delegate will likely scroll the content with the size change
        [self.delegate itemsViewAnimatingContentSizeChanges:self focusedRect:previousRect updatedFocusRect:updatedRect];
        
    } completion:^(BOOL finished) {

        [self removeItemPlaceholderViews];
    }];
}

#pragma mark - MenuItemActionableViewDelegate

- (void)itemActionableViewDidBeginReordering:(MenuItemActionableView *)actionableView
{
    [self.delegate itemsView:self prefersScrollingEnabled:NO];
}

- (void)itemActionableView:(MenuItemActionableView *)actionableView orderingTouchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event vector:(CGPoint)vector
{
    if(![actionableView isKindOfClass:[MenuItemActionableView class]]) {
        return;
    }
    
    const CGPoint touchPoint = [[touches anyObject] locationInView:self];
    MenuItemView *selectedItemView = (MenuItemView *)actionableView;
    
    // index of the itemView in the arrangedSubViews list
    const NSUInteger selectedItemViewIndex = [self.stackView.arrangedSubviews indexOfObject:selectedItemView];
    
    //// indentation detection (child relationships)
    
    // first check to see if we should pay attention to touches that might signal a change in indentation
    const CGFloat indentationDetectionXDelta = (selectedItemView.frame.size.width * 5.0) / 100; // a travel of x% should be considered
    if(fabs(vector.x) > indentationDetectionXDelta) {
     
        // look for any itemViews that might be above the selectedItemView
        MenuItemView *itemViewAboveSelected = nil;
        for(UIView *arrangedView in self.stackView.arrangedSubviews) {
            // ignore any other views that aren't itemViews
            if(![arrangedView isKindOfClass:[MenuItemView class]]) {
                continue;
            }
            if(arrangedView == selectedItemView) {
                break;
            }
            itemViewAboveSelected = (MenuItemView *)arrangedView;
        }
        
        // if there is an itemView above the selectedItemView, check for touches signaling a change in indentation
        if(itemViewAboveSelected) {
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
            // reset the vector to observe the next delta of interest
            [selectedItemView resetOrderingTouchesMovedVector];
        }
    }
    
    //// ordering detection
    
    // enumerate the itemViews lists since we don't care about other views in the stackView.arrangedSubviews list
    for(MenuItemView *itemView in self.itemViews) {
        if(itemView == selectedItemView) {
            continue;
        }
        // detect if the touch is looking to order the selectedItemView in place of another itemView by looking at the frame
        const CGRect orderingDetectionRect = CGRectInset(itemView.frame, 10.0, 10.0);
        if(CGRectContainsPoint(orderingDetectionRect, touchPoint)) {
            
            // update the indentationLevel to match the itemView we're replacing
            selectedItemView.indentationLevel = itemView.indentationLevel;

            // update the index of the itemView to the index of the selectedItemView
            [self.stackView insertArrangedSubview:itemView atIndex:selectedItemViewIndex];
            break;
        }
    }
}

- (void)itemActionableViewDidEndReordering:(MenuItemActionableView *)actionableView
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
    [self insertItemPlaceholderViewsAroundItemView:itemView animated:YES];
}

- (void)itemViewCancelButtonPressed:(MenuItemView *)itemView
{
    itemView.showsCancelButtonOption = NO;
    for(MenuItemView *childItemView in self.itemViews) {
        childItemView.showsEditingButtonOptions = YES;
    }
    [self removeItemPlaceholderViews:YES];
}

#pragma mark - MenuItemPlaceholderViewDelegate

- (void)itemPlaceholderViewSelected:(MenuItemPlaceholderView *)placeholderView
{
    // load the detail view for creating a new item
}

@end
