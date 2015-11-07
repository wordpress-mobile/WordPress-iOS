#import "MenusSelectionView.h"
#import "Menu.h"
#import "MenuLocation.h"
#import "MenusSelectionDetailView.h"
#import "MenusDesign.h"

@interface MenusSelectionView () <MenusSelectionDetailViewDelegate, MenusSelectionItemViewDelegate>

@property (nonatomic, weak) IBOutlet UIStackView *stackView;
@property (nonatomic, weak) IBOutlet MenusSelectionDetailView *detailView;
@property (nonatomic, strong) NSArray *items;
@property (nonatomic, strong) NSMutableArray *itemViews;
@property (nonatomic, strong) MenusSelectionViewItem *selectedItem;
@property (nonatomic, assign) BOOL drawsHighlighted;

@end

@implementation MenusSelectionView

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    self.translatesAutoresizingMaskIntoConstraints = NO;
    self.stackView.translatesAutoresizingMaskIntoConstraints = NO;
    self.stackView.alignment = UIStackViewAlignmentTop;
    self.stackView.spacing = 0.0;
    
    [self setupStyling];
    
    self.detailView.delegate = self;
}

- (void)setupStyling
{
    self.backgroundColor = [UIColor whiteColor];
    self.layer.cornerRadius = MenusDesignDefaultCornerRadius / 2.0;
    self.layer.masksToBounds = YES; // could be a performance hit with more implmentation
}

#pragma mark - instance

- (void)updateItems:(NSArray <MenusSelectionViewItem *> *)items
{
    self.items = items;
    
    MenusSelectionViewItem *selectedItem = nil;
    for(MenusSelectionViewItem *item in items) {
        if(item.selected) {
            selectedItem = item;
            break;
        }
    }
    
    self.selectedItem = selectedItem;
    
    if(self.selectionType == MenuSelectionViewTypeLocations) {
        
        [self.detailView updateWithAvailableLocations:items.count selectedLocationName:selectedItem.name];
        
    }else if(self.selectionType == MenuSelectionViewTypeMenus) {
        
        [self.detailView updateWithAvailableMenus:items.count selectedLocationName:selectedItem.name];
    }
    
    [self reloadItemViews];
}

- (void)setSelectionExpanded:(BOOL)selectionExpanded
{
    if(_selectionExpanded != selectionExpanded) {
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
    if(!animated) {
        self.selectionExpanded = selectionItemsExpanded;
        return;
    }
    
    [UIView animateWithDuration:0.25 delay:0.0 options:UIViewAnimationOptionCurveEaseOut animations:^{
        
        self.selectionExpanded = selectionItemsExpanded;
        
    } completion:^(BOOL finished) {
        
    }];
}

#pragma mark - private

- (void)reloadItemViews
{
    // remove the current itemViews
    for(UIView *view in self.itemViews) {
        [self.stackView removeArrangedSubview:view];
        [view removeFromSuperview];
    }
    
    self.itemViews = [NSMutableArray array];
    
    // add new itemViews
    int i = 0;
    MenusSelectionItemView *lastItemView = nil;
    for(MenusSelectionViewItem *item in self.items) {
                
        MenusSelectionItemView *itemView = [[MenusSelectionItemView alloc] init];
        itemView.item = item;
        itemView.delegate = self;
        
        // setup ordering to help with any drawing
        lastItemView.nextItemView = itemView;
        itemView.previousItemView = lastItemView;
        
        NSLayoutConstraint *heightContrainst = [itemView.heightAnchor constraintEqualToConstant:50];
        heightContrainst.priority = UILayoutPriorityDefaultHigh;
        heightContrainst.active = YES;
        itemView.hidden = YES;

        [self.itemViews addObject:itemView];
        [self.stackView addArrangedSubview:itemView];
        
        // set the width/trailing anchor equal to the stackView
        [itemView.trailingAnchor constraintEqualToAnchor:self.stackView.trailingAnchor].active = YES;
        
        i++;
        lastItemView = itemView;
    }
}

#pragma mark - drawing

- (void)setDrawsHighlighted:(BOOL)drawsHighlighted
{
    if(_drawsHighlighted != drawsHighlighted) {
        _drawsHighlighted = drawsHighlighted;
        self.backgroundColor = drawsHighlighted ? [UIColor colorWithRed:0.99 green:0.99 blue:1.0 alpha:1.0] : [UIColor whiteColor];
    }
}

#pragma mark - delegate helpers

- (void)tellDelegateUserInteractionDetectedForTogglingExpansion
{
    if([self.delegate respondsToSelector:@selector(userInteractionDetectedForTogglingSelectionView:expand:)]) {
        [self.delegate userInteractionDetectedForTogglingSelectionView:self expand:!self.selectionExpanded];
    }
}

- (void)tellDelegateUpdatedSelectedItem
{
    if([self.delegate respondsToSelector:@selector(selectionView:updatedSelectedItem:)]) {
        [self.delegate selectionView:self updatedSelectedItem:self.selectedItem];
    }
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
    self.selectedItem.selected = NO;
    self.selectedItem = itemView.item;
    itemView.item.selected = YES;
    
    if(self.selectionType == MenuSelectionViewTypeLocations) {
        
        [self.detailView updateWithAvailableLocations:self.items.count selectedLocationName:self.selectedItem.name];
        
    }else if(self.selectionType == MenuSelectionViewTypeMenus) {
        
        [self.detailView updateWithAvailableMenus:self.items.count selectedLocationName:self.selectedItem.name];
    }
    
    [self tellDelegateUpdatedSelectedItem];
}

@end
