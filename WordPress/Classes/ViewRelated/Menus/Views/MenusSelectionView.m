#import "MenusSelectionView.h"
#import "Menu.h"
#import "MenuLocation.h"
#import "MenusSelectionDetailView.h"
#import "MenusDesign.h"

@interface MenusSelectionView () <MenusSelectionDetailViewDelegate, MenusSelectionDetailViewDrawingDelegate>

@property (nonatomic, weak) IBOutlet UIStackView *stackView;
@property (nonatomic, weak) IBOutlet MenusSelectionDetailView *detailView;
@property (nonatomic, strong) NSArray *items;
@property (nonatomic, strong) MenusSelectionViewItem *selectedItem;
@property (nonatomic, strong) UIView *testView;
@property (nonatomic, assign) BOOL drawsHighlighted;

@end

@implementation MenusSelectionView

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    self.translatesAutoresizingMaskIntoConstraints = NO;

    self.stackView.translatesAutoresizingMaskIntoConstraints = NO;
    self.stackView.alignment = UIStackViewAlignmentTop;
    
    self.detailView.delegate = self;
    self.detailView.drawingDelegate = self;
    [self setupStyling];
    
    UIView *view = [[UIView alloc] init];
    view.translatesAutoresizingMaskIntoConstraints = NO;
    view.backgroundColor = [UIColor clearColor];
    NSLayoutConstraint *heightConstraint = [view.heightAnchor constraintEqualToConstant:100];
    heightConstraint.priority = UILayoutPriorityDefaultHigh;
    heightConstraint.active = YES;
    view.hidden = YES;
    self.testView = view;
    [self.stackView addArrangedSubview:view];
}

- (void)setupStyling
{
    self.backgroundColor = [UIColor whiteColor];
    self.layer.cornerRadius = MenusDesignDefaultCornerRadius / 2.0;
}

#pragma mark - INSTANCE

- (void)updateItems:(NSArray <MenusSelectionViewItem *> *)items selectedItem:(MenusSelectionViewItem *)selectedItem
{
    self.items = items;
    self.selectedItem = selectedItem;
    
    if(self.selectionType == MenuSelectionViewTypeLocations) {
        
        [self.detailView updateWithAvailableLocations:items.count selectedLocationName:selectedItem.name];
        
    }else if(self.selectionType == MenuSelectionViewTypeMenus) {
        
        [self.detailView updateWithAvailableMenus:items.count selectedLocationName:selectedItem.name];
    }
}

- (void)toggleSelectionExpansionIfNeeded:(BOOL)expanded animated:(BOOL)animated
{
    if(self.selectionItemsExpanded != expanded) {
        [self setSelectionItemsExpanded:expanded animated:animated];
    }
}

#pragma mark - PRIVATE

- (void)setSelectionItemsExpanded:(BOOL)selectionItemsExpanded
{
    if(_selectionItemsExpanded != selectionItemsExpanded) {
        _selectionItemsExpanded = selectionItemsExpanded;
        self.testView.hidden = !selectionItemsExpanded;
    }
}

- (void)setSelectionItemsExpanded:(BOOL)selectionItemsExpanded animated:(BOOL)animated
{
    if(!animated) {
        self.selectionItemsExpanded = selectionItemsExpanded;
        return;
    }
    
    [UIView animateWithDuration:0.5 delay:0.0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        
        self.selectionItemsExpanded = selectionItemsExpanded;
        
    } completion:^(BOOL finished) {
        
    }];
}

#pragma mark - drawing

- (void)setDrawsHighlighted:(BOOL)drawsHighlighted
{
    if(_drawsHighlighted != drawsHighlighted) {
        _drawsHighlighted = drawsHighlighted;
        self.backgroundColor = drawsHighlighted ? [UIColor colorWithRed:0.99 green:0.99 blue:1.0 alpha:1.0] : [UIColor whiteColor];
    }
}

#pragma mark - MenusSelectionDetailViewDelegate

- (void)selectionDetailViewPressedForTogglingExpansion:(MenusSelectionDetailView *)detailView
{
    // default animation to YES if the user pressed the view to expand/close
    [self setSelectionItemsExpanded:!self.selectionItemsExpanded animated:YES];
}

#pragma MenusSelectionDetailViewDrawingDelegate

- (void)selectionDetailView:(MenusSelectionDetailView *)detailView highlightedDrawingStateChanged:(BOOL)highlighted
{
    self.drawsHighlighted = highlighted;
}

@end
