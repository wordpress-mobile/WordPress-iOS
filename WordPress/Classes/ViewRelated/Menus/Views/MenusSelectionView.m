#import "MenusSelectionView.h"
#import "Menu.h"
#import "MenuLocation.h"
#import "MenusSelectionDetailView.h"
#import "MenusDesign.h"

@interface MenusSelectionView () <MenusSelectionDetailViewDelegate>

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

- (void)updateItems:(NSArray <MenusSelectionViewItem *> *)items selectedItem:(MenusSelectionViewItem *)selectedItem
{
    self.items = items;
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
    for(MenusSelectionViewItem *item in self.items) {
                
        MenusSelectionItemView *itemView = [[MenusSelectionItemView alloc] init];
        itemView.item = item;
        NSLayoutConstraint *heightContrainst = [itemView.heightAnchor constraintEqualToConstant:50];
        heightContrainst.priority = UILayoutPriorityDefaultHigh;
        heightContrainst.active = YES;
        itemView.hidden = YES;

        [self.itemViews addObject:itemView];
        [self.stackView addArrangedSubview:itemView];
        
        // set the width/trailing anchor equal to the stackView
        [itemView.trailingAnchor constraintEqualToAnchor:self.stackView.trailingAnchor].active = YES;
        
        if(i < self.items.count - 1) {
            itemView.drawsDesignStrokeBottom = YES;
        }
        
        i++;
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

#pragma mark - MenusSelectionDetailViewDelegate

- (void)selectionDetailView:(MenusSelectionDetailView *)detailView tapGestureRecognized:(UITapGestureRecognizer *)tap
{
    [self tellDelegateUserInteractionDetectedForTogglingExpansion];
}

- (void)selectionDetailView:(MenusSelectionDetailView *)detailView touchesHighlightedStateChanged:(BOOL)highlighted
{
    self.drawsHighlighted = highlighted;
}

@end
