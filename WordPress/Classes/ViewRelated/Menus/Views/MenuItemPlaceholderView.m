#import "MenuItemPlaceholderView.h"

@implementation MenuItemPlaceholderView

- (id)init
{
    self = [super init];
    if(self) {
        
        self.iconType = MenuItemActionableIconAdd;
        
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapGestureRecognized:)];
        [self.contentView addGestureRecognizer:tap];
    }
    
    return self;
}

- (UIColor *)contentViewBackgroundColor
{
    UIColor *color = nil;
    if(self.highlighted) {
        color = [super contentViewBackgroundColor];
    }else {
        color = [UIColor colorWithWhite:0.98 alpha:1.0];
    }
    
    return color;
}

- (void)setType:(MenuItemPlaceholderViewType)type
{
    if(_type != type) {
        _type = type;
        self.textLabel.text = [self textForType:type];
    }
}

- (NSString *)textForType:(MenuItemPlaceholderViewType)type
{
    NSString *text;
    switch (type) {
        case MenuItemPlaceholderViewTypeAbove:
            text = NSLocalizedString(@"Add menu item above", @"");
            break;
        case MenuItemPlaceholderViewTypeBelow:
            text = NSLocalizedString(@"Add menu item below", @"");
            break;
        case MenuItemPlaceholderViewTypeChild:
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
    [self.delegate itemPlaceholderViewSelected:self];
}

@end
