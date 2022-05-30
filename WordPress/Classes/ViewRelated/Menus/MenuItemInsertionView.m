#import "MenuItemInsertionView.h"
#import "WordPress-Swift.h"

@import Gridicons;

@implementation MenuItemInsertionView

@dynamic delegate;

- (id)init
{
    self = [super init];
    if (self) {

        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapGestureRecognized:)];
        [self.contentView addGestureRecognizer:tap];

        self.iconView.tintColor = [UIColor murielPrimary];
        self.iconView.image = [UIImage gridiconOfType:GridiconTypePlus];
    }

    return self;
}

- (void)setInsertionOrder:(MenuItemInsertionOrder)insertionOrder
{
    if (_insertionOrder != insertionOrder) {
        _insertionOrder = insertionOrder;
        self.textLabel.text = [self textForOrder:insertionOrder];
    }
}

- (NSString *)textForOrder:(MenuItemInsertionOrder)insertionOrder
{
    NSString *text;
    switch (insertionOrder) {
        case MenuItemInsertionOrderAbove:
            text = NSLocalizedString(@"Add menu item above", @"");
            break;
        case MenuItemInsertionOrderBelow:
            text = NSLocalizedString(@"Add menu item below", @"");
            break;
        case MenuItemInsertionOrderChild:
            text = NSLocalizedString(@"Add menu item to children", @"");
            break;
        default:
            text = nil;
            break;
    }

    return text;
}

- (UIColor *)textLabelColor
{
    UIColor *color = nil;
    if (self.highlighted) {
        color = [super textLabelColor];
    } else  {
        color = [UIColor murielPrimary];
    }

    return color;
}

#pragma mark - gestures

- (void)tapGestureRecognized:(UITapGestureRecognizer *)tap
{
    [self tellDelegateWasSelected];
}

#pragma mark - delegate helpers

- (void)tellDelegateWasSelected
{
    [self.delegate itemInsertionViewSelected:self];
}

@end
