#import "MenuItemInsertionView.h"

@implementation MenuItemInsertionView

@dynamic delegate;

- (id)init
{
    self = [super init];
    if (self) {
                
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapGestureRecognized:)];
        [self.contentView addGestureRecognizer:tap];
        
        self.iconView.image = [[UIImage imageNamed:@"menus-add"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    }
    
    return self;
}

- (UIColor *)contentViewBackgroundColor
{
    UIColor *color = nil;
    if (self.highlighted) {
        color = [super contentViewBackgroundColor];
    } else  {
        color = [UIColor colorWithRed:0.973 green:0.980 blue:0.984 alpha:1.000];
    }
    
    return color;
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
        color = [WPStyleGuide darkBlue];
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
