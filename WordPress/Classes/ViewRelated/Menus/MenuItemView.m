#import "MenuItemView.h"
#import "MenuItem.h"
#import "MenuItem+ViewDesign.h"
#import <WordPressShared/WPFontManager.h>
#import <WordPressShared/WPStyleGuide.h>
#import "WordPress-Swift.h"

@import Gridicons;

@interface MenuItemView ()

@property (nonatomic, strong, readonly) UIButton *addButton;
@property (nonatomic, strong, readonly) UIButton *orderingButton;
@property (nonatomic, strong, readonly) UIButton *cancelButton;
@property (nonatomic, assign) CGPoint touchesBeganLocation;

@end

@implementation MenuItemView

@dynamic delegate;

- (id)init
{
    self = [super init];
    if (self) {

        [self setupAddButton];
        [self setupOrderingButton];
        [self setupCancelButton];

        self.highlighted = NO;
    }

    return self;
}

- (void)setupAddButton
{
    UIButton *button = [self addAccessoryButtonIconViewWithImage:[Gridicon iconOfType:GridiconTypePlus]];
    [button addTarget:self action:@selector(addButtonPressed) forControlEvents:UIControlEventTouchUpInside];
    _addButton = button;
}

- (void)setupOrderingButton
{
    UIImage *image = [[UIImage imageNamed:@"menus-move-icon"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    UIButton *button = [self addAccessoryButtonIconViewWithImage:image];
    button.userInteractionEnabled = NO;
    _orderingButton = button;
}

- (void)setupCancelButton
{
    UIButton *button = [[UIButton alloc] init];
    [button addTarget:self action:@selector(cancelButtonPressed) forControlEvents:UIControlEventTouchUpInside];
    button.titleLabel.font = [WPStyleGuide fontForTextStyle:UIFontTextStyleBody maximumPointSize:[WPStyleGuide maxFontSize]];
    button.titleLabel.adjustsFontForContentSizeCategory = YES;
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

    _cancelButton = button;
}

- (void)setItem:(MenuItem *)item
{
    if (_item != item) {
        _item = item;
        [self refresh];
    }
}

- (void)setHighlighted:(BOOL)highlighted
{
    [super setHighlighted:highlighted];

    if (highlighted) {

        [self.cancelButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        self.addButton.tintColor = [UIColor whiteColor];
        self.orderingButton.tintColor = [UIColor whiteColor];

    } else {

        [self.cancelButton setTitleColor:[UIColor murielPrimary] forState:UIControlStateNormal];
        self.addButton.tintColor = [UIColor murielPrimary];
        self.orderingButton.tintColor = [UIColor murielTextTertiary];
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

        CGRect orderingButttonRect = [self convertRect:self.orderingButton.frame fromView:self.orderingButton.superview];
        if (CGRectContainsPoint(orderingButttonRect, endedPoint)) {
            // Ignore the selection if the touch ended within the ordering button.
            return;
        }
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
