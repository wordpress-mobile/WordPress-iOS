#import "MenuItemInsertionView.h"

@implementation MenuItemInsertionView

@dynamic delegate;

- (id)init
{
    self = [super init];
    if (self) {
        
        self.iconType = MenuIconTypeNone;
        
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapGestureRecognized:)];
        [self.contentView addGestureRecognizer:tap];
    }
    
    return self;
}

- (UIColor *)contentViewBackgroundColor
{
    UIColor *color = nil;
    if (self.highlighted) {
        color = [super contentViewBackgroundColor];
    } else  {
        color = [UIColor colorWithWhite:0.96 alpha:1.0];
    }
    
    return color;
}

- (void)setType:(MenuItemInsertionViewType)type
{
    if (_type != type) {
        _type = type;
        self.textLabel.text = [self textForType:type];
    }
}

- (NSString *)textForType:(MenuItemInsertionViewType)type
{
    NSString *text;
    switch (type) {
        case MenuItemInsertionViewTypeAbove:
            text = NSLocalizedString(@"Add menu item above", @"");
            break;
        case MenuItemInsertionViewTypeBelow:
            text = NSLocalizedString(@"Add menu item below", @"");
            break;
        case MenuItemInsertionViewTypeChild:
            text = NSLocalizedString(@"Add menu item to children", @"");
            break;
        default:
            text = nil;
            break;
    }
    
    return text;
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
