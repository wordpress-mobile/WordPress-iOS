#import "MenuItemsVisualOrderingView.h"
#import "MenuItemView.h"
#import "MenuItem.h"

@interface MenuItemsVisualOrderingView ()

@property (nonatomic, assign) CGRect startingOrderedItemViewFrame;
@property (nonatomic, strong) MenuItemView *orderingView;
@property (nonatomic, strong) MenuItemView *visualOrderingView;
@property (nonatomic, strong) NSLayoutConstraint *topConstraintForVisualTouchUpdates;

@end

@implementation MenuItemsVisualOrderingView

- (void)setVisualOrderingForItemView:(MenuItemView *)orderingView
{
    self.orderingView = orderingView;
    self.startingOrderedItemViewFrame = orderingView.frame;
    
    [self reloadItemViews];
}

- (void)updateForOrderingMenuItemsModelChange
{
    self.visualOrderingView.indentationLevel = self.orderingView.indentationLevel;
}

- (void)updateWithTouchLocation:(CGPoint)touchLocation vector:(CGPoint)vector
{
    CGFloat constraintConstValue = self.startingOrderedItemViewFrame.origin.y + vector.y;
    const CGFloat boundsPadding = 20.0;
    
    if(constraintConstValue < -boundsPadding) {
        constraintConstValue = -boundsPadding;
    }else  {

        const CGFloat maxY = (self.frame.size.height - self.visualOrderingView.frame.size.height) + boundsPadding;
        if(constraintConstValue > maxY) {
            constraintConstValue = maxY;
        }
    }
    
    self.topConstraintForVisualTouchUpdates.constant = constraintConstValue;
}

#pragma mark - private

- (void)reloadItemViews
{
    self.topConstraintForVisualTouchUpdates = nil;
    
    [self.visualOrderingView removeFromSuperview];
    self.visualOrderingView = nil;
    
    MenuItem *item = self.orderingView.item;
    
    CGRect layoutFrame = [self convertRect:self.orderingView.frame fromView:self.orderingView.superview];
    MenuItemView *itemView = [[MenuItemView alloc] init];
    itemView.showsEditingButtonOptions = NO;
    itemView.showsCancelButtonOption = NO;
    itemView.item = item;
    itemView.indentationLevel = self.orderingView.indentationLevel;
    itemView.alpha = 0.65;
    
    CALayer *contentLayer = itemView.contentView.layer;
    contentLayer.shadowColor = [[UIColor blackColor] CGColor];
    contentLayer.shadowOpacity = 0.3;
    contentLayer.shadowRadius = 10.0;
    contentLayer.shadowOffset = CGSizeMake(0, 0);
    
    NSLayoutConstraint *heightConstraint = [itemView.heightAnchor constraintEqualToConstant:MenuItemsStackableViewDefaultHeight];
    heightConstraint.active = YES;
    
    [self addSubview:itemView];
    self.visualOrderingView = itemView;
    
    NSLayoutConstraint *topConstraint = [itemView.topAnchor constraintEqualToAnchor:self.topAnchor];
    topConstraint.constant = layoutFrame.origin.y;
    self.topConstraintForVisualTouchUpdates = topConstraint;
    [NSLayoutConstraint activateConstraints:@[
                                              topConstraint,
                                              [itemView.leadingAnchor constraintEqualToAnchor:self.leadingAnchor],
                                              [itemView.trailingAnchor constraintEqualToAnchor:self.trailingAnchor]
                                              ]];
}

@end
