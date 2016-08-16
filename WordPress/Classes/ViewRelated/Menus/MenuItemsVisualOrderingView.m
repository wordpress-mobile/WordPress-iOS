#import "MenuItemsVisualOrderingView.h"
#import "MenuItemView.h"
#import "MenuItem.h"

@interface MenuItemsVisualOrderingView ()

@property (nonatomic, assign) CGRect startingOrderedItemViewFrame;
@property (nonatomic, strong) MenuItemView *itemView;
@property (nonatomic, strong) MenuItemView *visualOrderingView;
@property (nonatomic, strong) NSLayoutConstraint *topConstraintForVisualTouchUpdates;

@end

@implementation MenuItemsVisualOrderingView

- (void)setupVisualOrderingWithItemView:(MenuItemView *)itemView
{
    self.itemView = itemView;
    self.startingOrderedItemViewFrame = itemView.frame;

    [self reloadItemViews];
}

- (void)updateForVisualOrderingMenuItemsModelChange
{
    self.visualOrderingView.indentationLevel = self.itemView.indentationLevel;
}

- (void)updateVisualOrderingWithTouchLocation:(CGPoint)touchLocation vector:(CGPoint)vector
{
    CGFloat constraintConstValue = self.startingOrderedItemViewFrame.origin.y + vector.y;
    const CGFloat boundsPadding = 20.0;

    if (constraintConstValue < -boundsPadding) {
        constraintConstValue = -boundsPadding;
    } else   {

        const CGFloat maxY = (self.frame.size.height - self.visualOrderingView.frame.size.height) + boundsPadding;
        if (constraintConstValue > maxY) {
            constraintConstValue = maxY;
        }
    }

    self.topConstraintForVisualTouchUpdates.constant = constraintConstValue;

    if ([self.delegate respondsToSelector:@selector(visualOrderingView:animatingVisualItemViewForOrdering:)]) {
        [self.delegate visualOrderingView:self animatingVisualItemViewForOrdering:self.visualOrderingView];
    }
}

#pragma mark - private

- (void)reloadItemViews
{
    self.topConstraintForVisualTouchUpdates = nil;

    [self.visualOrderingView removeFromSuperview];
    self.visualOrderingView = nil;

    MenuItem *item = self.itemView.item;

    CGRect layoutFrame = [self convertRect:self.itemView.frame fromView:self.itemView.superview];
    MenuItemView *orderingView = [[MenuItemView alloc] init];
    orderingView.item = item;
    orderingView.indentationLevel = self.itemView.indentationLevel;
    orderingView.drawsLineSeparator = NO;
    orderingView.alpha = 0.65;
    orderingView.userInteractionEnabled = NO;

    CALayer *contentLayer = orderingView.contentView.layer;
    contentLayer.shadowColor = [[UIColor blackColor] CGColor];
    contentLayer.shadowOpacity = 0.3;
    contentLayer.shadowRadius = 10.0;
    contentLayer.shadowOffset = CGSizeMake(0, 0);

    NSLayoutConstraint *heightConstraint = [orderingView.heightAnchor constraintGreaterThanOrEqualToConstant:MenuItemsStackableViewDefaultHeight];
    heightConstraint.active = YES;

    [self addSubview:orderingView];
    self.visualOrderingView = orderingView;

    NSLayoutConstraint *topConstraint = [orderingView.topAnchor constraintEqualToAnchor:self.topAnchor];
    topConstraint.constant = layoutFrame.origin.y;
    self.topConstraintForVisualTouchUpdates = topConstraint;
    [NSLayoutConstraint activateConstraints:@[
                                              topConstraint,
                                              [orderingView.leadingAnchor constraintEqualToAnchor:self.leadingAnchor],
                                              [orderingView.trailingAnchor constraintEqualToAnchor:self.trailingAnchor]
                                              ]];
}

@end
