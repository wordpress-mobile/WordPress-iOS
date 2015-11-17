#import "MenuItemsView.h"
#import "Menu.h"
#import "MenuItem.h"
#import "WPStyleGuide.h"
#import "MenuItemsActionableView.h"
#import "MenuItemView.h"
#import "MenuItemPlaceholderView.h"
#import "MenusDesign.h"

@interface MenuItemsView () <MenuItemViewDelegate, MenuItemPlaceholderViewDelegate>

@property (nonatomic, weak) IBOutlet UIStackView *stackView;
@property (nonatomic, strong) NSMutableArray *itemViews;
@property (nonatomic, strong) NSMutableArray *placeholderViews;
@property (nonatomic, strong) MenuItemView *toggledItemView;

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
    for(MenuItemsActionableView *itemView in self.stackView.arrangedSubviews) {
        [self.stackView removeArrangedSubview:itemView];
        [itemView removeFromSuperview];
    }
    
    self.itemViews = [NSMutableArray array];
    self.placeholderViews = nil;
    
    MenuItemView *lastItemView = nil;
    for(MenuItem *item in self.menu.items) {
                
        MenuItemView *itemView = [[MenuItemView alloc] init];
        itemView.delegate = self;
        // set up ordering to help with any drawing
        itemView.item = item;
        lastItemView.nextView = itemView;
        itemView.previousView = lastItemView;
        itemView.indentationLevel = 1;

        MenuItem *parentItem = item.parent;
        while (parentItem) {
            itemView.indentationLevel++;
            parentItem = parentItem.parent;
        }
        
        NSLayoutConstraint *heightConstraint = [itemView.heightAnchor constraintEqualToConstant:MenuItemsActionableViewDefaultHeight];
        heightConstraint.priority = UILayoutPriorityDefaultHigh;
        heightConstraint.active = YES;
        
        [self.itemViews addObject:itemView];
        [self.stackView addArrangedSubview:itemView];
        
        [itemView.trailingAnchor constraintEqualToAnchor:self.stackView.trailingAnchor].active = YES;
        lastItemView = itemView;
    }
}

- (MenuItemPlaceholderView *)addNewBlankItemViewWithType:(MenuItemPlaceholderViewType)type forItemView:(MenuItemView *)itemView
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

    NSLayoutConstraint *heightConstraint = [placeholderView.heightAnchor constraintEqualToConstant:MenuItemsActionableViewDefaultHeight];
    heightConstraint.priority = UILayoutPriorityDefaultHigh;
    heightConstraint.active = YES;
    
    [self.placeholderViews addObject:placeholderView];
    [self.stackView insertArrangedSubview:placeholderView atIndex:index];
    
    [placeholderView.widthAnchor constraintEqualToAnchor:self.stackView.widthAnchor].active = YES;
    
    return placeholderView;
}

- (void)insertPlaceholderItemViewsAroundItemView:(MenuItemView *)toggledItemView
{
    self.toggledItemView = toggledItemView;
    
    self.placeholderViews = [NSMutableArray arrayWithCapacity:3];
    [self addNewBlankItemViewWithType:MenuItemPlaceholderViewTypeAbove forItemView:toggledItemView];
    [self addNewBlankItemViewWithType:MenuItemPlaceholderViewTypeBelow forItemView:toggledItemView];
    [self addNewBlankItemViewWithType:MenuItemPlaceholderViewTypeChild forItemView:toggledItemView];
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
    updatedRect.origin.y += MenuItemsActionableViewDefaultHeight;
    
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
    for(MenuItemsActionableView *itemView in self.placeholderViews) {
        [self.stackView removeArrangedSubview:itemView];
        [itemView removeFromSuperview];
    }
    
    self.placeholderViews = nil;
    [self.stackView setNeedsLayout];
    
    self.toggledItemView = nil;
}

- (void)removeItemPlaceholderViews:(BOOL)animated
{
    if(!animated) {
        [self removeItemPlaceholderViews];
        return;
    }
    
    CGRect previousRect = self.toggledItemView.frame;
    CGRect updatedRect = self.toggledItemView.frame;
    // since we are removing content above the toggledItemView, the toggledItemView (focus) will move upwards with the updated content size
    updatedRect.origin.y -= MenuItemsActionableViewDefaultHeight;
    
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
