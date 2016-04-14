#import "MenuItemView.h"
#import "MenuItem.h"
#import "WPStyleGuide.h"
#import "MenusActionButton.h"
#import "MenuItem+ViewDesign.h"
#import "WPFontManager.h"

@import Gridicons;

@interface MenuItemView ()

@property (nonatomic, strong) UIButton *addButton;
@property (nonatomic, strong) UIButton *orderingButton;
@property (nonatomic, strong) UIButton *cancelButton;
@property (nonatomic, assign) CGPoint touchesBeganLocation;

@end

@implementation MenuItemView

@dynamic delegate;

- (id)init
{
    self = [super init];
    if (self) {
        {
            UIButton *button = [self addAccessoryButtonIconViewWithImage:[Gridicon iconOfType:GridiconTypePlus]];
            button.tintColor = [WPStyleGuide wordPressBlue];
            [button addTarget:self action:@selector(addButtonPressed) forControlEvents:UIControlEventTouchUpInside];
            self.addButton = button;
        }
        {
            UIImage *image = [[UIImage imageNamed:@"menus-move-icon"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
            UIButton *button = [self addAccessoryButtonIconViewWithImage:image];
            button.tintColor = [WPStyleGuide greyLighten20];
            button.userInteractionEnabled = NO;
            self.orderingButton = button;
        }
        {
            UIButton *button = [[UIButton alloc] init];
            [button addTarget:self action:@selector(cancelButtonPressed) forControlEvents:UIControlEventTouchUpInside];
            [button setTitleColor:[WPStyleGuide wordPressBlue] forState:UIControlStateNormal];
            button.titleLabel.font = [WPFontManager systemRegularFontOfSize:16.0];
            [button setTitle:NSLocalizedString(@"Cancel", @"") forState:UIControlStateNormal];
            
            UIEdgeInsets inset = button.contentEdgeInsets;
            inset.left = 6.0;
            inset.right = inset.left;
            button.contentEdgeInsets = inset;
            button.hidden = YES;
            
            [self.accessoryStackView addArrangedSubview:button];
            [button setContentHuggingPriority:UILayoutPriorityDefaultHigh forAxis:UILayoutConstraintAxisHorizontal];
            [button setContentCompressionResistancePriority:UILayoutPriorityDefaultHigh forAxis:UILayoutConstraintAxisHorizontal];
            
            NSLayoutConstraint *heightConstraint = [button.heightAnchor constraintEqualToAnchor:self.accessoryStackView.heightAnchor];
            heightConstraint.priority = 999;
            heightConstraint.active = YES;
            
            self.cancelButton = button;
        }
    }
    
    return self;
}

- (void)setItem:(MenuItem *)item
{
    if (_item != item) {
        _item = item;
        [self refresh];
    }
}

- (void)refresh
{
    self.iconView.image = [MenuItem iconImageForItemType:self.item.type];
    self.textLabel.text = self.item.name;
}

- (CGRect)orderingToggleRect
{
    return [self convertRect:self.orderingButton.frame fromView:self.orderingButton.superview];
}

- (void)setShowsEditingButtonOptions:(BOOL)showsEditingButtonOptions
{
    if (_showsEditingButtonOptions != showsEditingButtonOptions) {
        _showsEditingButtonOptions = showsEditingButtonOptions;
    }
    self.addButton.hidden = !showsEditingButtonOptions;
}

- (void)setShowsCancelButtonOption:(BOOL)showsCancelButtonOption
{
    if (_showsCancelButtonOption != showsCancelButtonOption) {
        _showsCancelButtonOption = showsCancelButtonOption;
    }
    self.orderingButton.hidden = showsCancelButtonOption;
    self.cancelButton.hidden = !showsCancelButtonOption;
}

#pragma mark - buttons

- (void)addButtonPressed
{
    [self.delegate itemViewAddButtonPressed:self];
}

- (void)cancelButtonPressed
{
    [self.delegate itemViewCancelButtonPressed:self];
}

#pragma mark - touches

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    [super touchesBegan:touches withEvent:event];
    
    UITouch *touch = [touches anyObject];
    self.touchesBeganLocation = [touch locationInView:self];
}

- (void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    [super touchesMoved:touches withEvent:event];
    self.touchesBeganLocation = CGPointZero;
}

- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    [super touchesEnded:touches withEvent:event];
    
    UITouch *touch = [touches anyObject];
    if (CGPointEqualToPoint(self.touchesBeganLocation, CGPointZero)) {
        return;
    }
    
    CGPoint endedPoint = [touch locationInView:self];
    if (CGPointEqualToPoint(endedPoint, CGPointZero)) {
        return;
    }
    
    if (CGRectContainsPoint(self.bounds, self.touchesBeganLocation) && CGRectContainsPoint(self.bounds, endedPoint)) {
        [self.delegate itemViewSelected:self];
    }
    
    self.touchesBeganLocation = CGPointZero;
}

- (void)touchesCancelled:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    [super touchesCancelled:touches withEvent:event];
    self.touchesBeganLocation = CGPointZero;
}

@end
